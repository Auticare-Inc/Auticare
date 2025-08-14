import 'package:autismapp/repositories/cloudFunction.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/place.dart';
import 'GeofenceUtils.dart/geoModels.dart';
import 'GeofenceUtils.dart/geoService.dart' as geo;
import 'utilities/placesPageUtils/appColors.dart';
import 'GeofenceUtils.dart/placesProvider.dart';

class GeofencingMapsPage extends StatefulWidget {
  final Function()? onGeofenceUpdated;

  const GeofencingMapsPage({Key? key, this.onGeofenceUpdated})
      : super(key: key);

  @override
  _GeofencingMapsPageState createState() => _GeofencingMapsPageState();
}

class _GeofencingMapsPageState extends State<GeofencingMapsPage> {
  gmaps.GoogleMapController? _mapController;
  gmaps.LatLng? _childLocation; // kept for future child-tracking integration
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _timeCheckTimer;
  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Circle> _circles = {};
  bool _isLoading = true;
  String _locationStatus = 'Getting location...';
  bool _showGeofenceInfo = false;
  gmaps.BitmapDescriptor? _childIcon;
  gmaps.BitmapDescriptor? _deviceIcon;

  // Dynamic initial position - will be set once we get current location
  gmaps.CameraPosition? _initialPosition;

  // Default fallback position (Accra, Ghana)
  static const gmaps.CameraPosition _defaultPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(5.6037, -0.1870),
    zoom: 15,
  );

  Map<String, bool> _lastNotificationState = {};
  Map<String, DateTime> _lastNotificationTime = {};
  Map<String, bool> _lastTimeWindowState = {};
  static const Duration _notificationCooldown = Duration(minutes: 1);
  DateTime? _appStartTime;

  

  @override
  void initState() {
    super.initState();
    _appStartTime = DateTime.now();
    _initializeGeofencing();
    // periodic safety net (kept), but we’ll also check on every location update
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

      // Get current location first
      await _getCurrentLocation();

      await Provider.of<PlacesProvider>(context, listen: false)
          .initializeGeofencing();
      _loadActiveGeofences();
      _setupLocationTracking();

      setState(() {
        _isLoading = false;
        _locationStatus = _currentPosition != null
            ? 'Location acquired'
            : 'Location unavailable';
      });

      // Center on current location if available
      if (_currentPosition != null) {
        _centerOnDevice();
      } else if (Provider.of<PlacesProvider>(context, listen: false)
          .geofences
          .isNotEmpty) {
        _showAllGeofences();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleGeofenceCheck();
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error initializing geofencing: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _locationStatus = 'Error initializing: $e';
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _locationStatus = 'Getting current location...';
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location services are disabled';
          _initialPosition = _defaultPosition; // ensure map still renders
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permissions are denied';
            _initialPosition = _defaultPosition;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permissions are permanently denied';
          _initialPosition = _defaultPosition;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _initialPosition = gmaps.CameraPosition(
          target: gmaps.LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
        _locationStatus = 'Current location acquired';
        _updateMarkers();
      });
    } catch (e) {
      // ignore: avoid_print
      setState(() {
        _locationStatus = 'Error getting location: $e';
        _initialPosition = _defaultPosition; // Use default position as fallback
      });
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      _childIcon = await gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueGreen);
      _deviceIcon = await gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueBlue);
    } catch (e) {
      // ignore: avoid_print
      _childIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueBlue);
      _deviceIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed);
    }
  }

  void _loadActiveGeofences() {
    final geofences =
        Provider.of<PlacesProvider>(context, listen: false).geofences;
    // ignore: avoid_print
    _updateGeofenceCircles(geofences);
  }

  void _setupLocationTracking() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      _positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
        (position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
            _updateMarkers();
          });
          // ✅ Critical fix: evaluate geofence transitions immediately on movement
          _scheduleGeofenceCheck();
        },
        onError: (error) {
          // ignore: avoid_print
          print('Location stream error: $error');
          if (mounted) {
            setState(() {
              _locationStatus = 'Location stream error: $error';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Error setting up location tracking: $e';
        });
      }
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();

      // Add device location marker (current location)
      if (_currentPosition != null) {
        _markers.add(
          gmaps.Marker(
            markerId: const gmaps.MarkerId('device_location'),
            position: gmaps.LatLng(
                _currentPosition!.latitude, _currentPosition!.longitude),
            icon: _deviceIcon ??
                gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueBlue),
            infoWindow: gmaps.InfoWindow(
              title: ' Current Location',
              snippet:
                  'Device location\nLat: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
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
        // ignore: avoid_print
        print(
            'Adding circle for geofence: ${geofence.placeName}, lat: ${geofence.latitude}, lng: ${geofence.longitude}, radius: ${geofence.radius}');
        if (!geofence.isExpired && geofence.isActive) {
          final isWithinTimeWindow =
              geofence.isWithinTimeWindow(TimeOfDay.now());
          final isDeviceInside = _isDeviceInsideGeofence(geofence);
          Color circleColor;
          if (isDeviceInside && isWithinTimeWindow) {
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

  bool _isDeviceInsideGeofence(Geofence geofence) {
    if (_currentPosition == null) return false;
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      geofence.latitude,
      geofence.longitude,
    );
    return distance <= geofence.radius;
  }

  void _scheduleGeofenceCheck() {
    final geofences =
        Provider.of<PlacesProvider>(context, listen: false).geofences;

    if (_currentPosition == null) {
      // If we have any active geofences within their time window, alert that location is unavailable
      final activeGeofencesInTimeWindow = geofences
          .where((g) =>
              g.isActive &&
              !g.isExpired &&
              g.isWithinTimeWindow(TimeOfDay.now()))
          .toList();

      if (activeGeofencesInTimeWindow.isNotEmpty) {
        _showGeofenceNotification(null, false,
            'Device location not available during active geofence time window!');
        PushNotification.triggerPushNotification(
          title: 'Geofencing Alert - No Location',
          body:
              'Device location not available during active geofence time window!',
        );
      }
      return;
    }

    final currentTime = TimeOfDay.now();
    final now = DateTime.now();

    for (final geofence in geofences) {
      if (!geofence.isActive || geofence.isExpired) continue;

      final isInside = _isDeviceInsideGeofence(geofence);
      final isWithinTimeWindow = geofence.isWithinTimeWindow(currentTime);
      final geofenceKey = geofence.id.toString();

      final lastState = _lastNotificationState[geofenceKey];
      final lastTime = _lastNotificationTime[geofenceKey];
      final lastWindowState = _lastTimeWindowState[geofenceKey] ?? false;

      // ✅ Fix #2: allow notifications exactly at cooldown boundary
      final enoughTimePassed =
          lastTime == null || now.difference(lastTime) >= _notificationCooldown;
      
      // --- NEW: fire immediately when within window AND outside ---
if (isWithinTimeWindow && !isInside) {
  final last = _lastNotificationTime[geofenceKey];
  final cooldownOk = last == null || now.difference(last) >= _notificationCooldown;

  if (cooldownOk) {
    _showGeofenceNotification(
      geofence,
      false,
      'Child should be at ${geofence.placeName} now!',
    );
    PushNotification.triggerPushNotification(
      title: 'Geofencing Alert - Absent',
      body: 'Child should be at ${geofence.placeName} now!',
    );
    _lastNotificationTime[geofenceKey] = now;
  }

  // Lock state so we don’t double-notify later in this loop
  _lastNotificationState[geofenceKey] = false;
  _lastTimeWindowState[geofenceKey] = true;
  continue; // move to next geofence
}


      // Handle time window transitions
      if (lastWindowState != isWithinTimeWindow && enoughTimePassed) {
        if (isWithinTimeWindow) {
          // Time window just started
          if (isInside) {
            _showGeofenceNotification(geofence, true,
                'Time window started: Child are at ${geofence.placeName} as expected!');
            PushNotification.triggerPushNotification(
              title: 'Geofencing Alert - Time Window Started',
              body:
                  'Time window started: Child are at ${geofence.placeName} as expected!',
            );
          } else {
            _showGeofenceNotification(geofence, false,
                'Time window started: Child should be at ${geofence.placeName} now!');
            PushNotification.triggerPushNotification(
              title: 'Geofencing Alert - Time Window Started',
              body:
                  'Time window started: Child should be at ${geofence.placeName} now!',
            );
          }
          _lastNotificationTime[geofenceKey] = now;
          _lastNotificationState[geofenceKey] = isInside;
        } else if (lastWindowState) {
          // Time window just ended
          _showGeofenceNotification(
              geofence, false, 'Time window ended for ${geofence.placeName}');
          PushNotification.triggerPushNotification(
            title: 'Geofencing Alert - Time Window Ended',
            body: 'Time window ended for ${geofence.placeName}',
          );
          _lastNotificationTime[geofenceKey] = now;
          _lastNotificationState.remove(geofenceKey);
        }
        _lastTimeWindowState[geofenceKey] = isWithinTimeWindow;
      }

      // Handle arrivals/departures during active window
      else if (isWithinTimeWindow &&
          lastState != null &&
          lastState != isInside &&
          enoughTimePassed) {
        if (isInside) {
          _showGeofenceNotification(
              geofence, true, 'You have arrived at ${geofence.placeName}!');
          PushNotification.triggerPushNotification(
            title: 'Geofencing Alert - Arrival',
            body: 'You have arrived at ${geofence.placeName}!',
          );
        } else {
          _showGeofenceNotification(geofence, false,
              'You have left ${geofence.placeName} during scheduled time!');
          PushNotification.triggerPushNotification(
            title: 'Geofencing Alert - Departure',
            body: 'You have left ${geofence.placeName} during scheduled time!',
          );
        }
        _lastNotificationTime[geofenceKey] = now;
        _lastNotificationState[geofenceKey] = isInside;
      }

      // Initial evaluation inside an active window (avoid immediate spam on app launch)
      // else if (isWithinTimeWindow && lastState == null && enoughTimePassed) {
      //   if (now.difference(_appStartTime ?? now).inMinutes > 2) {
      //     if (isInside) {
      //       _showGeofenceNotification(geofence, true, 'You are at ${geofence.placeName} as scheduled!');
      //       PushNotification.triggerPushNotification(
      //         title: 'Geofencing Alert - Status Check',
      //         body: 'You are at ${geofence.placeName} as scheduled!',
      //       );
      //     } else {
      //       _showGeofenceNotification(geofence, false, 'You should be at ${geofence.placeName} now!');
      //       PushNotification.triggerPushNotification(
      //         title: 'Geofencing Alert - Status Check',
      //         body: 'You should be at ${geofence.placeName} now!',
      //       );
      //     }
      //     _lastNotificationTime[geofenceKey] = now;
      //   }
      //   _lastNotificationState[geofenceKey] = isInside;
      //   _lastTimeWindowState[geofenceKey] = isWithinTimeWindow;
      // }
      // Initial evaluation inside an active window.
// Notify immediately if NOT inside (!isInside). If inside, keep 2-minute grace.
      else if (isWithinTimeWindow && lastState == null && enoughTimePassed) {
        final allowNow = !isInside || // <-- negation does the trick
            now.difference(_appStartTime ?? now).inMinutes > 2;

        if (allowNow) {
          if (isInside) {
            _showGeofenceNotification(geofence, true,
                'You are at ${geofence.placeName} as scheduled!');
            PushNotification.triggerPushNotification(
              title: 'Geofencing Alert - Status Check',
              body: 'You are at ${geofence.placeName} as scheduled!',
            );
          } else {
            _showGeofenceNotification(
                geofence, false, 'You should be at ${geofence.placeName} now!');
            PushNotification.triggerPushNotification(
              title: 'Geofencing Alert - Status Check',
              body: 'You should be at ${geofence.placeName} now!',
            );
          }
          _lastNotificationTime[geofenceKey] = now;
        }

        _lastNotificationState[geofenceKey] = isInside;
        _lastTimeWindowState[geofenceKey] = isWithinTimeWindow;
      }

      // Keep window state tidy
      if (!isWithinTimeWindow) {
        _lastNotificationState.remove(geofenceKey);
        _lastTimeWindowState[geofenceKey] = false;
      } else {
        _lastTimeWindowState[geofenceKey] = isWithinTimeWindow;
        _lastNotificationState[geofenceKey] ??= isInside;
      }
    }

    _updateGeofenceCircles(geofences);
  }

  void _showGeofenceNotification(
      Geofence? geofence, bool isInside, String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isInside ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  void _showDeviceLocationInfo() {
    if (_currentPosition == null || !mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Current Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
            Text(
                'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 10),
            Text(
                'Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
            Text('Status: $_locationStatus'),
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

  void _centerOnDevice() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(
                _currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
          ),
        ),
      );
    } else {
      // ignore: avoid_print
      print(
          'Cannot center on device: mapController or currentPosition is null');
    }
  }

  void _showAllGeofences() {
    final geofences =
        Provider.of<PlacesProvider>(context, listen: false).geofences;
    if (geofences.isEmpty || _mapController == null) return;
    final bounds = _calculateBounds([
      if (_currentPosition != null)
        gmaps.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ...geofences.map((g) => gmaps.LatLng(g.latitude, g.longitude)),
    ]);
    _mapController!.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  gmaps.LatLngBounds _calculateBounds(List<gmaps.LatLng> points) {
    if (points.isEmpty) {
      return gmaps.LatLngBounds(
        southwest: gmaps.LatLng(5.6037, -0.1870),
        northeast: gmaps.LatLng(5.6037, -0.1870),
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
        return SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                // Only show the map when we have an initial position
                if (_initialPosition != null)
                  gmaps.GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (provider.geofences.isNotEmpty) {
                        _showAllGeofences();
                      } else if (_currentPosition != null) {
                        _centerOnDevice();
                      }
                    },
                    initialCameraPosition: _initialPosition!,
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
                  )
                else
                  // Show loading while getting initial position
                  Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
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
                                _initialPosition =
                                    _initialPosition ?? _defaultPosition;
                              });
                            },
                            child: const Text(''),
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
                            const SizedBox(height: 8),
                            Text(
                              'Active Geofences: ${provider.geofences.length}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blue),
                            ),
                            if (_currentPosition != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Device Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.blue),
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
                        height: 180,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Geofence Legend',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            _LegendItem(
                                color: Colors.green,
                                text: 'You are present at scheduled time'),
                            _LegendItem(
                                color: Colors.orange,
                                text: 'Time window active, you are absent'),
                            _LegendItem(
                                color: Colors.grey,
                                text: 'Outside time window'),
                            Divider(),
                            Text(
                              'Markers',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    color: Colors.blue, size: 16),
                                SizedBox(width: 4),
                                Text('Your Current Location',
                                    style: TextStyle(fontSize: 12)),
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
                        child:
                            const Icon(Icons.info_outline, color: Colors.white),
                        mini: true,
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "zoom_btn",
                        onPressed: _showAllGeofences,
                        backgroundColor: AppColors.primary,
                        child:
                            const Icon(Icons.zoom_out_map, color: Colors.white),
                        mini: true,
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "my_location_btn",
                        onPressed: _centerOnDevice,
                        backgroundColor: AppColors.primary,
                        child:
                            const Icon(Icons.my_location, color: Colors.white),
                        mini: true,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timeCheckTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
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
}
