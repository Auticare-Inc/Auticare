// import 'package:autismapp/screens/GeofenceUtils.dart/placesProvider.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
// import 'package:geolocator/geolocator.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:provider/provider.dart';
// import 'dart:async';
// import '../models/place.dart';
// import 'GeofenceUtils.dart/geoModels.dart';
// import 'GeofenceUtils.dart/geoService.dart' as geo;
// import 'utilities/placesPageUtils/appColors.dart';

// class GeofencingMapsPage extends StatefulWidget {
//   final Function()? onGeofenceUpdated; // Callback from PlacesScreen

//   const GeofencingMapsPage({Key? key, this.onGeofenceUpdated}) : super(key: key);

//   @override
//   _GeofencingMapsPageState createState() => _GeofencingMapsPageState();
// }

// class _GeofencingMapsPageState extends State<GeofencingMapsPage> {
//   gmaps.GoogleMapController? _mapController;
//   final geo.EnhancedGeofencingService _geofencingService = geo.EnhancedGeofencingService();
//   gmaps.LatLng? _childLocation;
//   Position? _currentPosition;
//   StreamSubscription<Position>? _positionStream;
//   StreamSubscription<DatabaseEvent>? _firebaseSubscription;
//   Set<gmaps.Marker> _markers = {};
//   Set<gmaps.Circle> _circles = {};
//   List<Geofence> _activeGeofences = [];
//   bool _isLoading = true;
//   String _locationStatus = 'Getting location...';
//   bool _showGeofenceInfo = false;
//   gmaps.BitmapDescriptor? _childIcon;
//   gmaps.BitmapDescriptor? _placeIcon;

//   static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
//     target: gmaps.LatLng(5.6037, -0.1870), // Accra, Ghana default
//     zoom: 15,
//   );

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _initializeGeofencing();
//   //   // Register callback for geofence updates
//   //   _geofencingService.onGeofencesUpdated = (geofences) {
//   //     setState(() {
//   //       _activeGeofences = geofences;
//   //       _updateGeofenceCircles();
//   //       _updateGeofenceMarkers();
//   //       if (_activeGeofences.isNotEmpty) {
//   //         _showAllGeofences();
//   //       }
//   //     });
//   //   };
//   //   // Register PlacesScreen callback
//   //   widget.onGeofenceUpdated?.call();
//   // }
//   @override
//   void initState() {
//     super.initState();
//     _initializeGeofencing();
//     _geofencingService.onGeofencesUpdated = (geofences) {
//       setState(() {
//         _activeGeofences = geofences;
//         _updateGeofenceCircles();
//         _updateGeofenceMarkers();
//         if (_activeGeofences.isNotEmpty) {
//           _showAllGeofences();
//         }
//       });
//     };
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Refresh geofences when page is revisited
//     _loadActiveGeofences();
//     widget.onGeofenceUpdated?.call();
//   }

//   // Future<void> _initializeGeofencing() async {
//   //   try {
//   //     setState(() {
//   //       _isLoading = true;
//   //       _locationStatus = 'Initializing...';
//   //     });

//   //     await _loadCustomIcons();
//   //     await _geofencingService.initialize();
//   //     _loadActiveGeofences();
//   //     _setupLocationTracking();
//   //     _startFirebaseLocationListener();

//   //     setState(() {
//   //       _isLoading = false;
//   //       _locationStatus = _childLocation != null ? 'Child location updated' : 'Waiting for location...';
//   //     });
//   //   } catch (e) {
//   //     print('Error initializing geofencing: $e');
//   //     setState(() {
//   //       _isLoading = false;
//   //       _locationStatus = 'Error initializing: $e';
//   //     });
//   //     _showErrorDialog('Initialization Error', 'Failed to initialize geofencing: $e');
//   //   }
//   // }

//   Future<void> _initializeGeofencing() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _locationStatus = 'Initializing...';
//       });
//       await _loadCustomIcons();
//       await _geofencingService.initialize();
//       _loadActiveGeofences();
//       _setupLocationTracking();
//       _startFirebaseLocationListener();
//       setState(() {
//         _isLoading = false;
//         _locationStatus = _childLocation != null ? 'Child location updated' : 'Waiting for location...';
//       });
//     } catch (e) {
//       print('Error initializing geofencing: $e');
//       setState(() {
//         _isLoading = false;
//         _locationStatus = 'Error initializing: $e';
//       });
//       _showErrorDialog('Initialization Error', 'Failed to initialize geofencing: $e');
//     }
//   }

//   Future<void> _loadCustomIcons() async {
//     try {
//       _childIcon = await gmaps.BitmapDescriptor.fromAssetImage(
//         const ImageConfiguration(size: Size(40, 40)),
//         'images/child_marker.png',
//       );
//       _placeIcon = await gmaps.BitmapDescriptor.fromAssetImage(
//         const ImageConfiguration(size: Size(35, 35)),
//         'images/place_marker.png',
//       );
//     } catch (e) {
//       print('Error loading custom icons: $e');
//       _childIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue);
//       _placeIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed);
//     }
//   }

//   void _loadActiveGeofences() {
//     setState(() {
//       _activeGeofences = _geofencingService.activeGeofences;
//       print('Loaded ${_activeGeofences.length} geofences: ${_activeGeofences.map((g) => "${g.placeName}: (${g.latitude}, ${g.longitude})")}');
//       _updateGeofenceCircles();
//       _updateGeofenceMarkers();
//       if (_activeGeofences.isNotEmpty) {
//         _showAllGeofences();
//       }
//     });
//   }

//   void _startFirebaseLocationListener() {
//     try {
//       final ref = FirebaseDatabase.instance.ref('test_write/location');
//       _firebaseSubscription = ref.limitToLast(1).onValue.listen(
//         (event) {
//           if (event.snapshot.exists) {
//             try {
//               final data = Map<String, dynamic>.from(event.snapshot.children.first.value as Map);
//               double latitude = data['latitude'];
//               double longitude = data['longitude'];
//               setState(() {
//                 _childLocation = gmaps.LatLng(latitude, longitude);
//                 _locationStatus = 'Child location updated';
//                 _updateChildLocationMarker();
//                 _checkGeofenceStatus();
//                 if (_mapController != null && _childLocation != null) {
//                   _mapController!.animateCamera(
//                     gmaps.CameraUpdate.newLatLng(_childLocation!),
//                   );
//                 }
//               });
//             } catch (e) {
//               print('Error parsing location data: $e');
//               setState(() {
//                 _locationStatus = 'Error parsing location data';
//               });
//             }
//           } else {
//             setState(() {
//               _locationStatus = 'No location data available';
//             });
//           }
//         },
//         onError: (error) {
//           print('Firebase listener error: $error');
//           setState(() {
//             _locationStatus = 'Firebase connection error';
//           });
//         },
//       );
//     } catch (e) {
//       print('Error setting up Firebase listener: $e');
//       setState(() {
//         _locationStatus = 'Failed to connect to Firebase';
//       });
//     }
//   }

//   void _setupLocationTracking() {
//     try {
//       const locationSettings = LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10,
//       );
//       _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
//         (position) {
//           setState(() {
//             _currentPosition = position;
//           });
//         },
//         onError: (error) {
//           print('Location stream error: $error');
//         },
//       );
//     } catch (e) {
//       print('Error setting up location tracking: $e');
//     }
//   }

//   void _updateChildLocationMarker() {
//     if (_childLocation == null) return;
//     setState(() {
//       _markers.removeWhere((marker) => marker.markerId.value == 'child_location');
//       _markers.add(
//         gmaps.Marker(
//           markerId: const gmaps.MarkerId('child_location'),
//           position: _childLocation!,
//           icon: _childIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue),
//           infoWindow: gmaps.InfoWindow(
//             title: 'Child Location',
//             snippet: 'Live tracked location\nLat: ${_childLocation!.latitude.toStringAsFixed(6)}\nLng: ${_childLocation!.longitude.toStringAsFixed(6)}',
//           ),
//           onTap: _showChildLocationInfo,
//         ),
//       );
//     });
//   }

//   void _updateGeofenceMarkers() {
//     setState(() {
//       _markers.removeWhere((marker) => marker.markerId.value.startsWith('geofence_'));
//       for (final geofence in _activeGeofences) {
//         print('Adding marker for geofence: ${geofence.placeName}, lat: ${geofence.latitude}, lng: ${geofence.longitude}');
//         if (!geofence.isExpired && geofence.isActive) {
//           _markers.add(
//             gmaps.Marker(
//               markerId: gmaps.MarkerId('geofence_${geofence.id}'),
//               position: gmaps.LatLng(geofence.latitude, geofence.longitude),
//               icon: _placeIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
//               infoWindow: gmaps.InfoWindow(
//                 title: geofence.placeName,
//                 snippet: 'Geofence active\nRadius: ${geofence.radius.toInt()}m\nTime: ${geofence.startTime.format(context)} - ${geofence.endTime.format(context)}',
//               ),
//               onTap: () => setState(() => _showGeofenceInfo = true),
//             ),
//           );
//         }
//       }
//     });
//   }

//   void _updateGeofenceCircles() {
//     setState(() {
//       _circles.clear();
//       for (final geofence in _activeGeofences) {
//         print('Adding circle for geofence: ${geofence.placeName}, lat: ${geofence.latitude}, lng: ${geofence.longitude}, radius: ${geofence.radius}');
//         if (!geofence.isExpired && geofence.isActive) {
//           final isWithinTimeWindow = geofence.isWithinTimeWindow(TimeOfDay.now());
//           final isChildInside = _isChildInsideGeofence(geofence);
//           Color circleColor;
//           if (isChildInside && isWithinTimeWindow) {
//             circleColor = Colors.green;
//           } else if (isWithinTimeWindow) {
//             circleColor = Colors.orange;
//           } else {
//             circleColor = Colors.grey;
//           }
//           _circles.add(
//             gmaps.Circle(
//               circleId: gmaps.CircleId('geofence_circle_${geofence.id}'),
//               center: gmaps.LatLng(geofence.latitude, geofence.longitude),
//               radius: geofence.radius,
//               fillColor: circleColor.withOpacity(0.2),
//               strokeColor: circleColor.withOpacity(0.8),
//               strokeWidth: 2,
//             ),
//           );
//         }
//       }
//     });
//   }

//   bool _isChildInsideGeofence(Geofence geofence) {
//     if (_childLocation == null) return false;
//     final distance = Geolocator.distanceBetween(
//       _childLocation!.latitude,
//       _childLocation!.longitude,
//       geofence.latitude,
//       geofence.longitude,
//     );
//     return distance <= geofence.radius;
//   }

//   void _checkGeofenceStatus() {
//     if (_childLocation == null) return;
//     final currentTime = TimeOfDay.now();
//     for (final geofence in _activeGeofences) {
//       if (!geofence.isActive || geofence.isExpired) continue;
//       final isInside = _isChildInsideGeofence(geofence);
//       final isWithinTimeWindow = geofence.isWithinTimeWindow(currentTime);
//       if (isInside && isWithinTimeWindow) {
//         _showGeofenceNotification(geofence, true);
//       } else if (isWithinTimeWindow && !isInside) {
//         _showGeofenceNotification(geofence, false);
//       }
//     }
//     _updateGeofenceCircles();
//   }

//   void _showGeofenceNotification(Geofence geofence, bool isInside) {
//     final message = isInside
//         ? 'Child is at ${geofence.placeName} as scheduled!'
//         : 'Child should be at ${geofence.placeName} now!';
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isInside ? Colors.green : Colors.orange,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showChildLocationInfo() {
//     if (_childLocation == null) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Child Location'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Latitude: ${_childLocation!.latitude.toStringAsFixed(6)}'),
//             Text('Longitude: ${_childLocation!.longitude.toStringAsFixed(6)}'),
//             const SizedBox(height: 10),
//             Text('Status: $_locationStatus'),
//             if (_currentPosition != null)
//               Text('Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _initializeGeofencing();
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _centerOnChild() {
//     if (_childLocation != null && _mapController != null) {
//       _mapController!.animateCamera(
//         gmaps.CameraUpdate.newCameraPosition(
//           gmaps.CameraPosition(
//             target: _childLocation!,
//             zoom: 18.0,
//           ),
//         ),
//       );
//     } else {
//       print('Cannot center: mapController or childLocation is null');
//     }
//   }

//   void _showAllGeofences() {
//     if (_activeGeofences.isEmpty || _mapController == null) return;
//     final bounds = _calculateBounds([
//       if (_childLocation != null) _childLocation!,
//       ..._activeGeofences.map((g) => gmaps.LatLng(g.latitude, g.longitude)),
//     ]);
//     _mapController!.animateCamera(
//       gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
//     );
//   }

//   gmaps.LatLngBounds _calculateBounds(List<gmaps.LatLng> points) {
//     if (points.isEmpty) {
//       return gmaps.LatLngBounds(
//         southwest: const gmaps.LatLng(5.6037, -0.1870),
//         northeast: const gmaps.LatLng(5.6037, -0.1870),
//       );
//     }
//     double minLat = points.first.latitude;
//     double maxLat = points.first.latitude;
//     double minLng = points.first.longitude;
//     double maxLng = points.first.longitude;
//     for (final point in points) {
//       minLat = minLat < point.latitude ? minLat : point.latitude;
//       maxLat = maxLat > point.latitude ? maxLat : point.latitude;
//       minLng = minLng < point.longitude ? minLng : point.longitude;
//       maxLng = maxLng > point.longitude ? maxLng : point.longitude;
//     }
//     return gmaps.LatLngBounds(
//       southwest: gmaps.LatLng(minLat - 0.01, minLng - 0.01),
//       northeast: gmaps.LatLng(maxLat + 0.01, maxLng + 0.01),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<PlacesProvider>(
//       builder:(context,provider,child){
//         _activeGeofences= provider.geofences;
//         return Scaffold(
//        appBar: AppBar(
//         title: const Text('Geofencing Monitor'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info_outline),
//             onPressed: () {
//               setState(() {
//                 _showGeofenceInfo = !_showGeofenceInfo;
//               });
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _initializeGeofencing,
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           gmaps.GoogleMap(
//             onMapCreated: (controller) {
//               _mapController = controller;
//               if (_activeGeofences.isNotEmpty) {
//                 _showAllGeofences();
//               } else if (_childLocation != null) {
//                 _centerOnChild();
//               }
//             },
//             initialCameraPosition: _initialPosition,
//             markers: _markers,
//             circles: _circles,
//             myLocationEnabled: false,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: true,
//             mapToolbarEnabled: false,
//             compassEnabled: true,
//             trafficEnabled: false,
//             buildingsEnabled: true,
//             mapType: gmaps.MapType.normal,
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.white.withOpacity(0.8),
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const CircularProgressIndicator(),
//                     const SizedBox(height: 16),
//                     Text(_locationStatus),
//                     const SizedBox(height: 8),
//                     TextButton(
//                       onPressed: () {
//                         setState(() {
//                           _isLoading = false;
//                         });
//                       },
//                       child: const Text('Skip Loading'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           if (!_isLoading)
//             Positioned(
//               top: 16,
//               left: 16,
//               right: 16,
//               child: Card(
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             color: _childLocation != null ? Colors.green : Colors.grey,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               _locationStatus,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w500,
//                                 color: _childLocation != null ? Colors.green : Colors.grey[600],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Active Geofences: ${_activeGeofences.length}',
//                         style: const TextStyle(fontSize: 12, color: Colors.blue),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           if (_showGeofenceInfo && !_isLoading)
//             Positioned(
//               bottom: 16,
//               left: 16,
//               right: 16,
//               child: Card(
//                 elevation: 4,
//                 child: Container(
//                   height: 200,
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Geofence Legend',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       _buildLegendItem(Colors.green, 'Child present at scheduled time'),
//                       _buildLegendItem(Colors.orange, 'Time window active, child absent'),
//                       _buildLegendItem(Colors.grey, 'Outside time window'),
//                       const Divider(),
//                       const Text(
//                         'Markers',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       const Row(
//                         children: [
//                           Icon(Icons.person_pin, color: Colors.blue, size: 16),
//                           SizedBox(width: 4),
//                           Text('Child Location', style: TextStyle(fontSize: 12)),
//                           SizedBox(width: 20),
//                           Icon(Icons.place, color: Colors.red, size: 16),
//                           SizedBox(width: 4),
//                           Text('Geofenced Places', style: TextStyle(fontSize: 12)),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: _isLoading
//           ? null
//           : Column(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 FloatingActionButton(
//                   heroTag: "show_all",
//                   onPressed: _showAllGeofences,
//                   backgroundColor: AppColors.primary,
//                   child: const Icon(Icons.zoom_out_map, color: Colors.white),
//                   mini: true,
//                 ),
//                 const SizedBox(height: 10),
//                 FloatingActionButton(
//                   heroTag: "center_child",
//                   onPressed: _centerOnChild,
//                   backgroundColor: Colors.blue,
//                   child: const Icon(Icons.my_location, color: Colors.white),
//                 ),
//               ],
//             ),
//     );
//     }
//     );
//   }

//   Widget _buildLegendItem(Color color, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Container(
//             width: 16,
//             height: 16,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               border: Border.all(color: color.withOpacity(0.8), width: 2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _firebaseSubscription?.cancel();
//     _geofencingService.dispose();
//     super.dispose();
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
// import 'package:geolocator/geolocator.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:provider/provider.dart';
// import 'dart:async';
// import '../models/place.dart';
// import 'GeofenceUtils.dart/geoModels.dart';
// import 'GeofenceUtils.dart/geoService.dart' as geo;
// import 'utilities/placesPageUtils/appColors.dart';
// import 'GeofenceUtils.dart/placesProvider.dart';

// class GeofencingMapsPage extends StatefulWidget {
//   final Function()? onGeofenceUpdated;

//   const GeofencingMapsPage({Key? key, this.onGeofenceUpdated}) : super(key: key);

//   @override
//   _GeofencingMapsPageState createState() => _GeofencingMapsPageState();
// }

// class _GeofencingMapsPageState extends State<GeofencingMapsPage> {
//   gmaps.GoogleMapController? _mapController;
//   gmaps.LatLng? _childLocation;
//   Position? _currentPosition;
//   StreamSubscription<Position>? _positionStream;
//   StreamSubscription<DatabaseEvent>? _firebaseSubscription;
//   Timer? _timeCheckTimer;
//   Set<gmaps.Marker> _markers = {};
//   Set<gmaps.Circle> _circles = {};
//   bool _isLoading = true;
//   String _locationStatus = 'Getting location...';
//   bool _showGeofenceInfo = false;
//   gmaps.BitmapDescriptor? _childIcon;

//   static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
//     target: gmaps.LatLng(5.6037, -0.1870), // Accra, Ghana default
//     zoom: 15,
//   );

//   @override
//   void initState() {
//     super.initState();
//     _initializeGeofencing();
//     // Start a timer to check geofence time windows every minute
//     _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
//       _checkGeofenceStatus();
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Refresh geofences when page is revisited
//     _loadActiveGeofences();
//     widget.onGeofenceUpdated?.call();
//   }

//   Future<void> _initializeGeofencing() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _locationStatus = 'Initializing...';
//       });
//       await _loadCustomIcons();
//       await Provider.of<PlacesProvider>(context, listen: false).initializeGeofencing();
//       _loadActiveGeofences();
//       _setupLocationTracking();
//       _startFirebaseLocationListener();
//       setState(() {
//         _isLoading = false;
//         _locationStatus = _childLocation != null ? 'Child location updated' : 'Waiting for location...';
//       });
//       // Center map after initialization
//       if (_childLocation != null) {
//         _centerOnChild();
//       } else if (Provider.of<PlacesProvider>(context, listen: false).geofences.isNotEmpty) {
//         _showAllGeofences();
//       }
//     } catch (e) {
//       print('Error initializing geofencing: $e');
//       setState(() {
//         _isLoading = false;
//         _locationStatus = 'Error initializing: $e';
//       });
//       _showErrorDialog('Initialization Error', 'Failed to initialize geofencing: $e');
//     }
//   }

//   Future<void> _loadCustomIcons() async {
//     try {
//       _childIcon = await gmaps.BitmapDescriptor.fromAssetImage(
//         const ImageConfiguration(size: Size(40, 40)),
//         'images/child_marker.png',
//       );
//     } catch (e) {
//       print('Error loading custom icon: $e');
//       _childIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue);
//     }
//   }

//   void _loadActiveGeofences() {
//     setState(() {
//       final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
//       print('Loaded ${geofences.length} geofences: ${geofences.map((g) => "${g.placeName}: (${g.latitude}, ${g.longitude})")}');
//       _updateGeofenceCircles(geofences);
//       _checkGeofenceStatus();
//       if (geofences.isNotEmpty && _childLocation == null) {
//         _showAllGeofences();
//       }
//     });
//   }

//   void _startFirebaseLocationListener() {
//     try {
//       final ref = FirebaseDatabase.instance.ref('test_write/location');
//       _firebaseSubscription = ref.limitToLast(1).onValue.listen(
//         (event) {
//           if (event.snapshot.exists) {
//             try {
//               final data = Map<String, dynamic>.from(event.snapshot.children.first.value as Map);
//               double latitude = data['latitude'];
//               double longitude = data['longitude'];
//               setState(() {
//                 _childLocation = gmaps.LatLng(latitude, longitude);
//                 _locationStatus = 'Child location updated';
//                 _updateChildLocationMarker();
//                 _checkGeofenceStatus();
//                 if (_mapController != null && _childLocation != null) {
//                   _centerOnChild();
//                 }
//               });
//             } catch (e) {
//               print('Error parsing location data: $e');
//               setState(() {
//                 _locationStatus = 'Error parsing location data';
//               });
//             }
//           } else {
//             setState(() {
//               _locationStatus = 'No location data available';
//               _childLocation = null;
//               _updateChildLocationMarker();
//               _checkGeofenceStatus();
//             });
//           }
//         },
//         onError: (error) {
//           print('Firebase listener error: $error');
//           setState(() {
//             _locationStatus = 'Firebase connection error';
//           });
//         },
//       );
//     } catch (e) {
//       print('Error setting up Firebase listener: $e');
//       setState(() {
//         _locationStatus = 'Failed to connect to Firebase';
//       });
//     }
//   }

//   void _setupLocationTracking() {
//     try {
//       const locationSettings = LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10,
//       );
//       _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
//         (position) {
//           setState(() {
//             _currentPosition = position;
//           });
//         },
//         onError: (error) {
//           print('Location stream error: $error');
//         },
//       );
//     } catch (e) {
//       print('Error setting up location tracking: $e');
//     }
//   }

//   void _updateChildLocationMarker() {
//     setState(() {
//       _markers.clear(); // Only keep child location marker
//       if (_childLocation != null) {
//         _markers.add(
//           gmaps.Marker(
//             markerId: const gmaps.MarkerId('child_location'),
//             position: _childLocation!,
//             icon: _childIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue),
//             infoWindow: gmaps.InfoWindow(
//               title: 'Child Location',
//               snippet: 'Live tracked location\nLat: ${_childLocation!.latitude.toStringAsFixed(6)}\nLng: ${_childLocation!.longitude.toStringAsFixed(6)}',
//             ),
//             onTap: _showChildLocationInfo,
//           ),
//         );
//       }
//     });
//   }

//   void _updateGeofenceCircles(List<Geofence> geofences) {
//     setState(() {
//       _circles.clear();
//       for (final geofence in geofences) {
//         print('Adding circle for geofence: ${geofence.placeName}, lat: ${geofence.latitude}, lng: ${geofence.longitude}, radius: ${geofence.radius}');
//         if (!geofence.isExpired && geofence.isActive) {
//           final isWithinTimeWindow = geofence.isWithinTimeWindow(TimeOfDay.now());
//           final isChildInside = _isChildInsideGeofence(geofence);
//           Color circleColor;
//           if (isChildInside && isWithinTimeWindow) {
//             circleColor = Colors.green;
//           } else if (isWithinTimeWindow) {
//             circleColor = Colors.orange;
//           } else {
//             circleColor = Colors.grey;
//           }
//           _circles.add(
//             gmaps.Circle(
//               circleId: gmaps.CircleId('geofence_circle_${geofence.id}'),
//               center: gmaps.LatLng(geofence.latitude, geofence.longitude),
//               radius: geofence.radius,
//               fillColor: circleColor.withOpacity(0.2),
//               strokeColor: circleColor.withOpacity(0.8),
//               strokeWidth: 2,
//             ),
//           );
//         }
//       }
//     });
//   }

//   bool _isChildInsideGeofence(Geofence geofence) {
//     if (_childLocation == null) return false;
//     final distance = Geolocator.distanceBetween(
//       _childLocation!.latitude,
//       _childLocation!.longitude,
//       geofence.latitude,
//       geofence.longitude,
//     );
//     return distance <= geofence.radius;
//   }

//   void _checkGeofenceStatus() {
//     final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
//     if (_childLocation == null) {
//       if (geofences.any((g) => g.isActive && !g.isExpired && g.isWithinTimeWindow(TimeOfDay.now()))) {
//         _showGeofenceNotification(null, false, 'Child location not available during active geofence time window!');
//       }
//       return;
//     }
//     final currentTime = TimeOfDay.now();
//     bool isInsideAnyGeofence = false;
//     for (final geofence in geofences) {
//       if (!geofence.isActive || geofence.isExpired) continue;
//       final isInside = _isChildInsideGeofence(geofence);
//       final isWithinTimeWindow = geofence.isWithinTimeWindow(currentTime);
//       if (isInside && isWithinTimeWindow) {
//         isInsideAnyGeofence = true;
//         _showGeofenceNotification(geofence, true, 'Child is at ${geofence.placeName} as scheduled!');
//       } else if (isWithinTimeWindow && !isInside) {
//         _showGeofenceNotification(geofence, false, 'Child should be at ${geofence.placeName} now!');
//       }
//     }
//     if (!isInsideAnyGeofence && geofences.any((g) => g.isActive && !g.isExpired && g.isWithinTimeWindow(currentTime))) {
//       _showGeofenceNotification(null, false, 'Child is not in any active geofence during scheduled time!');
//     }
//     _updateGeofenceCircles(geofences);
//   }

//   void _showGeofenceNotification(Geofence? geofence, bool isInside, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isInside ? Colors.green : Colors.red,
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }

//   void _showChildLocationInfo() {
//     if (_childLocation == null) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Child Location'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Latitude: ${_childLocation!.latitude.toStringAsFixed(6)}'),
//             Text('Longitude: ${_childLocation!.longitude.toStringAsFixed(6)}'),
//             const SizedBox(height: 10),
//             Text('Status: $_locationStatus'),
//             if (_currentPosition != null)
//               Text('Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _initializeGeofencing();
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _centerOnChild() {
//     if (_childLocation != null && _mapController != null) {
//       _mapController!.animateCamera(
//         gmaps.CameraUpdate.newCameraPosition(
//           gmaps.CameraPosition(
//             target: _childLocation!,
//             zoom: 18.0,
//           ),
//         ),
//       );
//     } else {
//       print('Cannot center: mapController or childLocation is null');
//     }
//   }

//   void _showAllGeofences() {
//     final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
//     if (geofences.isEmpty || _mapController == null) return;
//     final bounds = _calculateBounds([
//       if (_childLocation != null) _childLocation!,
//       ...geofences.map((g) => gmaps.LatLng(g.latitude, g.longitude)),
//     ]);
//     _mapController!.animateCamera(
//       gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
//     );
//   }

//   gmaps.LatLngBounds _calculateBounds(List<gmaps.LatLng> points) {
//     if (points.isEmpty) {
//       return gmaps.LatLngBounds(
//         southwest: const gmaps.LatLng(5.6037, -0.1870),
//         northeast: const gmaps.LatLng(5.6037, -0.1870),
//       );
//     }
//     double minLat = points.first.latitude;
//     double maxLat = points.first.latitude;
//     double minLng = points.first.longitude;
//     double maxLng = points.first.longitude;
//     for (final point in points) {
//       minLat = minLat < point.latitude ? minLat : point.latitude;
//       maxLat = maxLat > point.latitude ? maxLat : point.latitude;
//       minLng = minLng < point.longitude ? minLng : point.longitude;
//       maxLng = maxLng > point.longitude ? maxLng : point.longitude;
//     }
//     return gmaps.LatLngBounds(
//       southwest: gmaps.LatLng(minLat - 0.01, minLng - 0.01),
//       northeast: gmaps.LatLng(maxLat + 0.01, maxLng + 0.01),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<PlacesProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           appBar: AppBar(
//             title: const Text('Geofencing Monitor'),
//             backgroundColor: AppColors.primary,
//             foregroundColor: Colors.white,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.info_outline),
//                 onPressed: () {
//                   setState(() {
//                     _showGeofenceInfo = !_showGeofenceInfo;
//                   });
//                 },
//               ),
//               IconButton(
//                 icon: const Icon(Icons.refresh),
//                 onPressed: _initializeGeofencing,
//               ),
//             ],
//           ),
//           body: Stack(
//             children: [
//               gmaps.GoogleMap(
//                 onMapCreated: (controller) {
//                   _mapController = controller;
//                   if (provider.geofences.isNotEmpty) {
//                     _showAllGeofences();
//                   } else if (_childLocation != null) {
//                     _centerOnChild();
//                   }
//                 },
//                 initialCameraPosition: _initialPosition,
//                 markers: _markers,
//                 circles: _circles,
//                 myLocationEnabled: false,
//                 myLocationButtonEnabled: false,
//                 zoomControlsEnabled: true,
//                 mapToolbarEnabled: false,
//                 compassEnabled: true,
//                 trafficEnabled: false,
//                 buildingsEnabled: true,
//                 mapType: gmaps.MapType.normal,
//               ),
//               if (_isLoading)
//                 Container(
//                   color: Colors.white.withOpacity(0.8),
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const CircularProgressIndicator(),
//                         const SizedBox(height: 16),
//                         Text(_locationStatus),
//                         const SizedBox(height: 8),
//                         TextButton(
//                           onPressed: () {
//                             setState(() {
//                               _isLoading = false;
//                             });
//                           },
//                           child: const Text('Skip Loading'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               if (!_isLoading)
//                 Positioned(
//                   top: 16,
//                   left: 16,
//                   right: 16,
//                   child: Card(
//                     elevation: 4,
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.location_on,
//                                 color: _childLocation != null ? Colors.green : Colors.grey,
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   _locationStatus,
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w500,
//                                     color: _childLocation != null ? Colors.green : Colors.grey[600],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Active Geofences: ${provider.geofences.length}',
//                             style: const TextStyle(fontSize: 12, color: Colors.blue),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               if (_showGeofenceInfo && !_isLoading)
//                 Positioned(
//                   bottom: 16,
//                   left: 16,
//                   right: 16,
//                   child: Card(
//                     elevation: 4,
//                     child: Container(
//                       height: 200,
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Geofence Legend',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           _buildLegendItem(Colors.green, 'Child present at scheduled time'),
//                           _buildLegendItem(Colors.orange, 'Time window active, child absent'),
//                           _buildLegendItem(Colors.grey, 'Outside time window'),
//                           const Divider(),
//                           const Text(
//                             'Markers',
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 4),
//                           const Row(
//                             children: [
//                               Icon(Icons.person_pin, color: Colors.blue, size: 16),
//                               SizedBox(width: 4),
//                               Text('Child Location', style: TextStyle(fontSize: 12)),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           floatingActionButton: _isLoading
//               ? null
//               : Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     FloatingActionButton(
//                       heroTag: "show_all",
//                       onPressed: _showAllGeofences,
//                       backgroundColor: AppColors.primary,
//                       child: const Icon(Icons.zoom_out_map, color: Colors.white),
//                       mini: true,
//                     ),
//                     const SizedBox(height: 10),
//                     FloatingActionButton(
//                       heroTag: "center_child",
//                       onPressed: _centerOnChild,
//                       backgroundColor: Colors.blue,
//                       child: const Icon(Icons.my_location, color: Colors.white),
//                     ),
//                   ],
//                 ),
//         );
//       },
//     );
//   }

//   Widget _buildLegendItem(Color color, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Container(
//             width: 16,
//             height: 16,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               border: Border.all(color: color.withOpacity(0.8), width: 2),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     _firebaseSubscription?.cancel();
//     _timeCheckTimer?.cancel();
//     _mapController?.dispose();
//     super.dispose();
//   }
// }

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

  static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(5.6037, -0.1870), // Accra, Ghana default
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
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
      } else if (Provider.of<PlacesProvider>(context, listen: false).geofences.isNotEmpty) {
        _showAllGeofences();
      }
      // Schedule initial geofence check after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleGeofenceCheck();
      });
    } catch (e) {
      print('Error initializing geofencing: $e');
      setState(() {
        _isLoading = false;
        _locationStatus = 'Error initializing: $e';
      });
      _showErrorDialog('Initialization Error', 'Failed to initialize geofencing: $e');
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      _childIcon = await gmaps.BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)),
        'images/child_marker.png',
      );
    } catch (e) {
      print('Error loading custom icon: $e');
      _childIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue);
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
      final ref = FirebaseDatabase.instance.ref('test_write/location');
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
                _updateChildLocationMarker();
                if (_mapController != null && _childLocation != null) {
                  _centerOnChild();
                }
              });
              // Schedule geofence check after location update
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scheduleGeofenceCheck();
              });
            } catch (e) {
              print('Error parsing location data: $e');
              setState(() {
                _locationStatus = 'Error parsing location data';
                _childLocation = null;
                _updateChildLocationMarker();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scheduleGeofenceCheck();
              });
            }
          } else {
            setState(() {
              _locationStatus = 'No location data available';
              _childLocation = null;
              _updateChildLocationMarker();
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
          });
        },
        onError: (error) {
          print('Location stream error: $error');
        },
      );
    } catch (e) {
      print('Error setting up location tracking: $e');
    }
  }

  void _updateChildLocationMarker() {
    setState(() {
      _markers.clear();
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

  void _scheduleGeofenceCheck() {
    final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
    if (_childLocation == null) {
      if (geofences.any((g) => g.isActive && !g.isExpired && g.isWithinTimeWindow(TimeOfDay.now()))) {
        _showGeofenceNotification(null, false, 'Child location not available during active geofence time window!');
      }
      return;
    }
    final currentTime = TimeOfDay.now();
    bool isInsideAnyGeofence = false;
    for (final geofence in geofences) {
      if (!geofence.isActive || geofence.isExpired) continue;
      final isInside = _isChildInsideGeofence(geofence);
      final isWithinTimeWindow = geofence.isWithinTimeWindow(currentTime);
      if (isInside && isWithinTimeWindow) {
        isInsideAnyGeofence = true;
        _showGeofenceNotification(geofence, true, 'Child is at ${geofence.placeName} as scheduled!');
        PushNotification.triggerPushNotification(
          title: 'Geofencing Alert', 
          body: 'Child is at ${geofence.placeName} as scheduled!');
      } else if (isWithinTimeWindow && !isInside) {
        _showGeofenceNotification(geofence, false, 'Child should be at ${geofence.placeName} now!');
      }
    }
    if (!isInsideAnyGeofence && geofences.any((g) => g.isActive && !g.isExpired && g.isWithinTimeWindow(currentTime))) {
      _showGeofenceNotification(null, false, 'Child is not in any active geofence during scheduled time!');
      PushNotification.triggerPushNotification(
        title: 'Geofencing alert', 
        body: 'Child is not in any active geofence during scheduled time');
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

  void _showErrorDialog(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeGeofencing();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    });
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
      print('Cannot center: mapController or childLocation is null');
    }
  }

  void _showAllGeofences() {
    final geofences = Provider.of<PlacesProvider>(context, listen: false).geofences;
    if (geofences.isEmpty || _mapController == null) return;
    final bounds = _calculateBounds([
      if (_childLocation != null) _childLocation!,
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
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _childLocation != null ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationStatus,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _childLocation != null ? Colors.green : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Active Geofences: ${provider.geofences.length}',
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                          ),
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
                      height: 200,
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
                      onPressed: ()=> _initializeGeofencing,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.refresh, color: Colors.white),
                      mini: true,
                    ),
                    SizedBox(height:10),
                    FloatingActionButton(
                      heroTag: "info_btn",
                      onPressed: (){
                        setState(() {
                       _showGeofenceInfo = !_showGeofenceInfo;
                       });
                      },
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.info_outline, color: Colors.white),
                      mini: true,
                    ),
                    SizedBox(height:10),
                    FloatingActionButton(
                      heroTag: "zoom_btn",
                      onPressed: _showAllGeofences,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.zoom_out_map, color: Colors.white),
                      mini: true,
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: "center_child_btn",
                      onPressed: _centerOnChild,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.my_location, color: Colors.white),
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