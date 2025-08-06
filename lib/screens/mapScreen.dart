
import 'package:autismapp/repositories/cloudFunction.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/place.dart';
import 'GeofenceUtils.dart/geoModels.dart';
import 'GeofenceUtils.dart/geoService.dart' as geo;
import 'utilities/placesPageUtils/appColors.dart';
import 'GeofenceUtils.dart/placesProvider.dart';

class GeofencingMapsPage extends StatefulWidget {
  final Function()? onGeofenceUpdated;

  const GeofencingMapsPage({Key? key, this.onGeofenceUpdated}) : super(key: key);

  @override
  _GeofencingMapsPageState createState() => _GeofencingMapsPageState();
}

class _GeofencingMapsPageState extends State<GeofencingMapsPage> {
  gmaps.GoogleMapController? _mapController;
  gmaps.LatLng? _childLocation;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DatabaseEvent>? _firebaseSubscription;
  Timer? _timeCheckTimer;
  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Circle> _circles = {};
  bool _isLoading = true;
  String _locationStatus = 'Getting location...';
  bool _showGeofenceInfo = false;
  gmaps.BitmapDescriptor? _childIcon;
  gmaps.BitmapDescriptor? _deviceIcon; // Added for device location marker

  static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(5.6037, -0.1870), // Accra, Ghana default
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _appStartTime = DateTime.now();
    _initializeGeofencing();
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _scheduleGeofenceCheck();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActiveGeofences();
    widget.onGeofenceUpdated?.call();
  }

  Future<void> _initializeGeofencing() async {
    try {
      setState(() {
        _isLoading = true;
        _locationStatus = 'Initializing...';
      });
      await _loadCustomIcons();
      await Provider.of<PlacesProvider>(context, listen: false).initializeGeofencing();
      _loadActiveGeofences();
      _setupLocationTracking();
      _startFirebaseLocationListener();
      setState(() {
        _isLoading = false;
        _locationStatus = _childLocation != null ? 'Child location updated' : 'Waiting for location...';
      });
      if (_childLocation != null) {
        _centerOnChild();
      } else if (_currentPosition != null) {
        _centerOnDevice(); // Center on device if child location is unavailable
      } else if (Provider.of<PlacesProvider>(context, listen: false).geofences.isNotEmpty) {
        _showAllGeofences();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleGeofenceCheck();
      });
    } catch (e) {
      print('Error initializing geofencing: $e');
      setState(() {
        _isLoading = false;
        _locationStatus = 'Error initializing: $e';
      });
     // _showErrorDialog('Initialization Error', 'Failed to initialize geofencing: $e');
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      _childIcon = await gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen);
      _deviceIcon = await gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue);
    } catch (e) {
      print('Error loading custom icons: $e');
      _childIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue);
      _deviceIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed); // Default for device
    }
  }

  void _loadActiveGeofences() {
    setState(() {
      final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
      print('Loaded ${geofences.length} geofences: ${geofences.map((g) => "${g.placeName}: (${g.latitude}, ${g.longitude})")}');
      _updateGeofenceCircles(geofences);
    });
  }

  void _startFirebaseLocationListener() {
    try {
      final ref = FirebaseDatabase.instance.ref('test_write_location');
      _firebaseSubscription = ref.limitToLast(1).onValue.listen(
        (event) {
          if (event.snapshot.exists) {
            try {
              final data = Map<String, dynamic>.from(event.snapshot.children.first.value as Map);
              double latitude = data['latitude'];
              double longitude = data['longitude'];
              setState(() {
                _childLocation = gmaps.LatLng(latitude, longitude);
                _locationStatus = 'Child location updated';
                _updateMarkers();
                if (_mapController != null && _childLocation != null) {
                  _centerOnChild();
                }
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scheduleGeofenceCheck();
              });
            } catch (e) {
              print('Error parsing location data: $e');
              setState(() {
                _locationStatus = 'Error parsing location data';
                _childLocation = null;
                _updateMarkers();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scheduleGeofenceCheck();
              });
            }
          } else {
            setState(() {
              _locationStatus = 'No location data available';
              _childLocation = null;
              _updateMarkers();
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scheduleGeofenceCheck();
            });
          }
        },
        onError: (error) {
          print('Firebase listener error: $error');
          setState(() {
            _locationStatus = 'Firebase connection error';
          });
        },
      );
    } catch (e) {
      print('Error setting up Firebase listener: $e');
      setState(() {
        _locationStatus = 'Failed to connect to Firebase';
      });
    }
  }

  void _setupLocationTracking() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (position) {
          setState(() {
            _currentPosition = position;
            _updateMarkers();
          });
        },
        onError: (error) {
          print('Location stream error: $error');
          setState(() {
            _locationStatus = 'Location stream error: $error';
          });
        },
      );
    } catch (e) {
      print('Error setting up location tracking: $e');
      setState(() {
        _locationStatus = 'Error setting up location tracking: $e';
      });
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      // Add child location marker
      if (_childLocation != null) {
        _markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId('child_location'),
            position: _childLocation!,
            icon: _childIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue),
            infoWindow: gmaps.InfoWindow(
              title: 'Child Location',
              snippet: 'Live tracked location\nLat: ${_childLocation!.latitude.toStringAsFixed(6)}\nLng: ${_childLocation!.longitude.toStringAsFixed(6)}',
            ),
            onTap: _showChildLocationInfo,
          ),
        );
      }
      // Add device location marker
      if (_currentPosition != null) {
        _markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId('device_location'),
            position: gmaps.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: _deviceIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
            infoWindow: gmaps.InfoWindow(
              title: 'Device Location',
              snippet: 'Child location location\nLat: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
            ),
            onTap: _showDeviceLocationInfo,
          ),
        );
      }
    });
  }

  void _updateGeofenceCircles(List<Geofence> geofences) {
    setState(() {
      _circles.clear();
      for (final geofence in geofences) {
        print('Adding circle for geofence: ${geofence.placeName}, lat: ${geofence.latitude}, lng: ${geofence.longitude}, radius: ${geofence.radius}');
        if (!geofence.isExpired && geofence.isActive) {
          final isWithinTimeWindow = geofence.isWithinTimeWindow(TimeOfDay.now());
          final isChildInside = _isChildInsideGeofence(geofence);
          Color circleColor;
          if (isChildInside && isWithinTimeWindow) {
            circleColor = Colors.green;
          } else if (isWithinTimeWindow) {
            circleColor = Colors.orange;
          } else {
            circleColor = Colors.grey;
          }
          _circles.add(
            gmaps.Circle(
              circleId: gmaps.CircleId('geofence_circle_${geofence.id}'),
              center: gmaps.LatLng(geofence.latitude, geofence.longitude),
              radius: geofence.radius,
              fillColor: circleColor.withOpacity(0.2),
              strokeColor: circleColor.withOpacity(0.8),
              strokeWidth: 2,
            ),
          );
        }
      }
    });
  }

  bool _isChildInsideGeofence(Geofence geofence) {
    if (_childLocation == null) return false;
    final distance = Geolocator.distanceBetween(
      _childLocation!.latitude,
      _childLocation!.longitude,
      geofence.latitude,
      geofence.longitude,
    );
    return distance <= geofence.radius;
  }

  Map<String, bool> _lastNotificationState = {}; // Track last notification state for each geofence
  Map<String, DateTime> _lastNotificationTime = {}; // Track when we last sent a notification
  Map<String, bool> _lastTimeWindowState = {};
  static const Duration _notificationCooldown = Duration(minutes: 1); // Cooldown period between notifications
  DateTime? _appStartTime;

  // ... existing methods ...

  // void _scheduleGeofenceCheck() {
  //   final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
    
  //   if (_childLocation == null) {
  //     // Check if there are any active geofences within time window
  //     if (geofences.any((g) => g.isActive && !g.isExpired && g.isWithinTimeWindow(TimeOfDay.now()))) {
  //       _showGeofenceNotification(null, false, 'Child location not available during active geofence time window!');
  //       PushNotification.triggerPushNotification(
  //         title: 'Geofencing Alert',
  //         body: 'Child location not available during active geofence time window!',
  //       );
  //     }
  //     return;
  //   }

  //   final currentTime = TimeOfDay.now();
  //   final now = DateTime.now();

  //   for (final geofence in geofences) {
  //     if (!geofence.isActive || geofence.isExpired) continue;
      
  //     final isInside = _isChildInsideGeofence(geofence);
  //     final isWithinTimeWindow = geofence.isWithinTimeWindow(currentTime);
  //     final geofenceKey = geofence.id.toString();
      
  //     // Only process if within time window
  //     if (isWithinTimeWindow) {
  //       // Check if we need to send a notification (state changed or enough time passed)
  //       final lastState = _lastNotificationState[geofenceKey];
  //       final lastNotificationTime = _lastNotificationTime[geofenceKey];
  //       final shouldNotify = lastState != isInside || 
  //         (lastNotificationTime == null || 
  //          now.difference(lastNotificationTime) > _notificationCooldown);

  //       if (shouldNotify) {
  //         if (isInside) {
  //           // Child is inside the geofence during scheduled time
  //           _showGeofenceNotification(geofence, true, 'Child is at ${geofence.placeName} as scheduled!');
  //           PushNotification.triggerPushNotification(
  //             title: 'Geofencing Alert - Arrival',
  //             body: 'Child has arrived at ${geofence.placeName} as scheduled!',
  //           );
  //           print('DEBUG: Child INSIDE geofence ${geofence.placeName} during scheduled time');
  //         } else {
  //           // Child should be at this geofence but is not
  //           _showGeofenceNotification(geofence, false, 'Child should be at ${geofence.placeName} now!');
  //           PushNotification.triggerPushNotification(
  //             title: 'Geofencing Alert - Missing',
  //             body: 'Child should be at ${geofence.placeName} but is not there!',
  //           );
  //           print('DEBUG: Child OUTSIDE geofence ${geofence.placeName} during scheduled time');
  //         }
          
  //         // Update tracking variables
  //         _lastNotificationState[geofenceKey] = isInside;
  //         _lastNotificationTime[geofenceKey] = now;
  //       }
  //     } else {
  //       // Outside time window - reset state
  //       _lastNotificationState.remove(geofenceKey);
  //       _lastNotificationTime.remove(geofenceKey);
  //     }
  //   }

  //   _updateGeofenceCircles(geofences);
  // }
  void _scheduleGeofenceCheck() {
  final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
  
  if (_childLocation == null) {
    // Check if there are any active geofences within time window
    final activeGeofencesInTimeWindow = geofences.where(
      (g) => g.isActive && !g.isExpired && g.isWithinTimeWindow(TimeOfDay.now())
    ).toList();
    
    if (activeGeofencesInTimeWindow.isNotEmpty) {
      _showGeofenceNotification(null, false, 'Child location not available during active geofence time window!');
      PushNotification.triggerPushNotification(
        title: 'Geofencing Alert - No Location',
        body: 'Child location not available during active geofence time window!',
      );
    }
    return;
  }

  final currentTime = TimeOfDay.now();
  final now = DateTime.now();

  for (final geofence in geofences) {
    if (!geofence.isActive || geofence.isExpired) continue;
    
    final isInside = _isChildInsideGeofence(geofence);
    final isWithinTimeWindow = geofence.isWithinTimeWindow(currentTime);
    final geofenceKey = geofence.id.toString();
    
    // Get previous states
    final lastState = _lastNotificationState[geofenceKey];
    final lastNotificationTime = _lastNotificationTime[geofenceKey];
    final lastTimeWindowState = _lastTimeWindowState[geofenceKey] ?? false;
    
    // Check if enough time has passed since last notification
    final enoughTimePassed = lastNotificationTime == null || 
        now.difference(lastNotificationTime) > _notificationCooldown;
    
    // Handle time window changes
    if (lastTimeWindowState != isWithinTimeWindow && enoughTimePassed) {
      if (isWithinTimeWindow) {
        // Time window just started
        if (isInside) {
          _showGeofenceNotification(geofence, true, 'Time window started: Child is at ${geofence.placeName} as expected!');
          PushNotification.triggerPushNotification(
            title: 'Geofencing Alert - Time Window Started',
            body: 'Time window started: Child is at ${geofence.placeName} as expected!',
          );
        } else {
          _showGeofenceNotification(geofence, false, 'Time window started: Child should be at ${geofence.placeName} now!');
          PushNotification.triggerPushNotification(
            title: 'Geofencing Alert - Time Window Started',
            body: 'Time window started: Child should be at ${geofence.placeName} now!',
          );
        }
        _lastNotificationTime[geofenceKey] = now;
        _lastNotificationState[geofenceKey] = isInside;
      } else if (lastTimeWindowState) {
        // Time window just ended
        _showGeofenceNotification(geofence, false, 'Time window ended for ${geofence.placeName}');
        PushNotification.triggerPushNotification(
          title: 'Geofencing Alert - Time Window Ended',
          body: 'Time window ended for ${geofence.placeName}',
        );
        _lastNotificationTime[geofenceKey] = now;
        // Clear the state when time window ends
        _lastNotificationState.remove(geofenceKey);
      }
      _lastTimeWindowState[geofenceKey] = isWithinTimeWindow;
    }
    
    // Handle location changes within active time window
    else if (isWithinTimeWindow && lastState != null && lastState != isInside && enoughTimePassed) {
      if (isInside) {
        // Child just arrived
        _showGeofenceNotification(geofence, true, 'Child has arrived at ${geofence.placeName}!');
        PushNotification.triggerPushNotification(
          title: 'Geofencing Alert - Arrival',
          body: 'Child has arrived at ${geofence.placeName}!',
        );
      } else{
        // Child just left
          _showGeofenceNotification(geofence, false, 'Child has left ${geofence.placeName} during scheduled time!');
        PushNotification.triggerPushNotification(
          title: 'Geofencing Alert - Departure',
          body: 'Child has left ${geofence.placeName} during scheduled time!',
        );
      }
      _lastNotificationTime[geofenceKey] = now;
      _lastNotificationState[geofenceKey] = isInside;
    }
    
    // Handle initial state when geofence is first processed
    else if (isWithinTimeWindow && lastState == null && enoughTimePassed) {
      // This is the first time we're checking this geofence in the time window
      // Only notify if it's been long enough since app started to avoid immediate notifications
      if (now.difference(_appStartTime ?? now).inMinutes > 2) {
        if (isInside) {
          _showGeofenceNotification(geofence, true, 'Child is at ${geofence.placeName} as scheduled!');
          PushNotification.triggerPushNotification(
            title: 'Geofencing Alert - Status Check',
            body: 'Child is at ${geofence.placeName} as scheduled!',
          );
        } else {
          _showGeofenceNotification(geofence, false, 'Child should be at ${geofence.placeName} now!');
          PushNotification.triggerPushNotification(
            title: 'Geofencing Alert - Status Check',
            body: 'Child should be at ${geofence.placeName} now!',
          );
        }
        _lastNotificationTime[geofenceKey] = now;
      }
      _lastNotificationState[geofenceKey] = isInside;
      _lastTimeWindowState[geofenceKey] = isWithinTimeWindow;
    }
    
    // Update states for next check
    if (!isWithinTimeWindow) {
      // Clear states when outside time window
      _lastNotificationState.remove(geofenceKey);
      _lastTimeWindowState[geofenceKey] = false;
    } else {
      _lastTimeWindowState[geofenceKey] = isWithinTimeWindow;
      if (_lastNotificationState[geofenceKey] == null) {
        _lastNotificationState[geofenceKey] = isInside;
      }
    }
  }

  _updateGeofenceCircles(geofences);
}

  void _showGeofenceNotification(Geofence? geofence, bool isInside, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isInside ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  void _showChildLocationInfo() {
    if (_childLocation == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Child Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${_childLocation!.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${_childLocation!.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 10),
            Text('Status: $_locationStatus'),
            if (_currentPosition != null)
              Text('Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeviceLocationInfo() {
    if (_currentPosition == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 10),
            Text('Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _centerOnChild() {
    if (_childLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: _childLocation!,
            zoom: 18.0,
          ),
        ),
      );
    } else {
      print('Cannot center on child: mapController or childLocation is null');
    }
  }

  void _centerOnDevice() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
          ),
        ),
      );
    } else {
      print('Cannot center on device: mapController or currentPosition is null');
    }
  }

  void _showAllGeofences() {
    final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
    if (geofences.isEmpty || _mapController == null) return;
    final bounds = _calculateBounds([
      if (_childLocation != null) _childLocation!,
      if (_currentPosition != null) gmaps.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ...geofences.map((g) => gmaps.LatLng(g.latitude, g.longitude)),
    ]);
    _mapController!.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  gmaps.LatLngBounds _calculateBounds(List<gmaps.LatLng> points) {
    if (points.isEmpty) {
      return gmaps.LatLngBounds(
        southwest: const gmaps.LatLng(5.6037, -0.1870),
        northeast: const gmaps.LatLng(5.6037, -0.1870),
      );
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat - 0.01, minLng - 0.01),
      northeast: gmaps.LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlacesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Stack(
            children: [
              gmaps.GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (provider.geofences.isNotEmpty) {
                    _showAllGeofences();
                  } else if (_childLocation != null) {
                    _centerOnChild();
                  } else if (_currentPosition != null) {
                    _centerOnDevice();
                  }
                },
                initialCameraPosition: _initialPosition,
                markers: _markers,
                circles: _circles,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                compassEnabled: true,
                trafficEnabled: false,
                buildingsEnabled: true,
                mapType: gmaps.MapType.normal,
              ),
              if (_isLoading)
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_locationStatus),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          child: const Text('Skip Loading'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isLoading)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Row(
                          //   children: [
                          //     Icon(
                          //       Icons.location_on,
                          //       color: _childLocation != null || _currentPosition != null ? Colors.green : Colors.grey,
                          //       size: 20,
                          //     ),
                          //     const SizedBox(width: 8),
                          //     Expanded(
                          //       child: Text(
                          //         _locationStatus,
                          //         style: TextStyle(
                          //           fontWeight: FontWeight.w500,
                          //           color: _childLocation != null || _currentPosition != null ? Colors.green : Colors.grey[600],
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 8),
                          Text(
                            'Active Geofences: ${provider.geofences.length}',
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                          if (_currentPosition != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Device: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showGeofenceInfo && !_isLoading)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    child: Container(
                      height: 220, // Increased height to accommodate new legend item
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Geofence Legend',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLegendItem(Colors.green, 'Child present at scheduled time'),
                          _buildLegendItem(Colors.orange, 'Time window active, child absent'),
                          _buildLegendItem(Colors.grey, 'Outside time window'),
                          const Divider(),
                          const Text(
                            'Markers',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.person_pin, color: Colors.blue, size: 16),
                              SizedBox(width: 4),
                              Text('Child Location', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.phone_android, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text('Device Location', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: _isLoading
              ? null
              : Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: "refresh_btn",
                      onPressed: _initializeGeofencing,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.refresh, color: Colors.white),
                      mini: true,
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: "info_btn",
                      onPressed: () {
                        setState(() {
                          _showGeofenceInfo = !_showGeofenceInfo;
                        });
                      },
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.info_outline, color: Colors.white),
                      mini: true,
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: "zoom_btn",
                      onPressed: _showAllGeofences,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.zoom_out_map, color: Colors.white),
                      mini: true,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              border: Border.all(color: color.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _firebaseSubscription?.cancel();
    _timeCheckTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}