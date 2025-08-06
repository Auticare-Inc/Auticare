// import 'dart:async';
// import 'package:autismapp/app.dart';
// import 'package:autismapp/models/FirestoreDatabase.dart';
// import 'package:autismapp/screens/healthMonitoring.dart';
// import 'package:autismapp/screens/resultsPage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:autismapp/screens/mapScreen.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'GeofenceUtils.dart/geoManagementPage.dart';
// import 'utilities/dashboardUtils/dashboardMap.dart';
// import 'utilities/dashboardUtils/location.dart';

// class ChildSafetyDashboard extends StatefulWidget {
//   @override
//   _ChildSafetyDashboardState createState() => _ChildSafetyDashboardState();
// }

// class _ChildSafetyDashboardState extends State<ChildSafetyDashboard> {
//   int _selectedIndex = 0;
//   bool _isGeofencingEnabled = true;
//   String _lastUpdate = "2 min ago";
//   String _status = "Child is calm and inside the safe zone";
//   String _currentLocation = "Home - Living Room";
//   String _batteryLevel = "85%";
//   bool _isInSafeZone = true;

//   late GoogleMapController mapController;
//   LocationService locationService = LocationService();
//   Marker? currentLocationMarker;
//   late LatLng currentLocation;
//   StreamSubscription<Position>? positionStreamSubscription;
//   double? Latitude;
//   double? Longitude;

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocation();
//   }

//   Future<void> _initializeLocation() async {
//     await setLocation();
//     _setupLocationStream();
//   }

//   Future<void> setLocation() async {
//     await locationService.setLocation(
//         (LatLng location, Marker marker, Map<String, dynamic> data) {
//       if (mounted) {
//         setState(() {
//           currentLocation = location;
//           currentLocationMarker = marker;
//         });
//       }
//     });
//   }

//   void _setupLocationStream() {
//     positionStreamSubscription = locationService.getLocationStream().listen(
//       (Position position) {
//         if (mounted) {
//           setState(() {
//             currentLocation = LatLng(position.latitude, position.longitude);
//             currentLocationMarker = Marker(
//               markerId: const MarkerId("currentLocation"),
//               position: currentLocation,
//               infoWindow: InfoWindow(
//                   title: "Current Location", snippet: "Live tracking"),
//             );
//           });
//         }
//       },
//       onError: (error) {
//         print("Location stream error: $error");
//       },
//     );
//   }

//   Future<Map<String, dynamic>?> _getCurrentLocation() async {
//     final cached = locationService.getCachedLocation();
//     if (cached != null) {
//       return cached;
//     }
//     return await locationService.getCurrentLocation();
//   }

//   @override
//   void dispose() {
//     positionStreamSubscription?.cancel();
//     super.dispose();
//   }

//   Widget _getCurrentPage() {
//     switch (_selectedIndex) {
//       case 0:
//         return _buildHomePage();
//       case 1:
//         return GeofencingMapsPage();
//       case 2:
//         return HRHRVMonitorPage();
//       case 3:
//         return GeofenceManagementPage();
//       default:
//         return _buildHomePage();
//     }
//   }

//   String _formatCurrentTime() {
//     final now = DateTime.now();
//     final hour =
//         now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
//     final minute = now.minute.toString().padLeft(2, '0');
//     final period = now.hour >= 12 ? 'PM' : 'AM';
//     return '$hour:$minute $period';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       // appBar: AppBar(
//       //   backgroundColor: Colors.transparent,
//       //   elevation: 0,
//       //   leading: Padding(
//       //     padding: const EdgeInsets.only(left: 10),
//       //     child: Container(
//       //       margin: EdgeInsets.all(8),
//       //       decoration: BoxDecoration(
//       //         color: Colors.black,
//       //         shape: BoxShape.circle,
//       //       ),
//       //       child: Icon(
//       //         Icons.child_care,
//       //         color: Colors.white,
//       //         size: 20,
//       //       ),
//       //     ),
//       //   ),
//       //   actions: [
//       //     Padding(
//       //       padding: const EdgeInsets.only(right: 15),
//       //       child: Row(
//       //         mainAxisSize: MainAxisSize.min,
//       //         children: [
//       //           Flexible(
//       //             child: Text(
//       //               'Auticare',
//       //               style: TextStyle(
//       //                 fontWeight: FontWeight.bold,
//       //                 fontSize: 24,
//       //                 color: Color.fromRGBO(56, 83, 106, 1),
//       //               ),
//       //               overflow: TextOverflow.ellipsis,
//       //             ),
//       //           ),
//       //         ],
//       //       ),
//       //     )
//       //   ],
//       // ),
//       body: _getCurrentPage(),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//             HapticFeedback.lightImpact();
//           },
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.white,
//           selectedItemColor: Colors.blue,
//           unselectedItemColor: Colors.grey[600],
//           selectedLabelStyle:
//               TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//           unselectedLabelStyle: TextStyle(fontSize: 12),
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home_outlined),
//               activeIcon: Icon(Icons.home),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.location_on_outlined),
//               activeIcon: Icon(Icons.location_on),
//               label: 'Tracking',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.favorite_outline),
//               activeIcon: Icon(Icons.favorite),
//               label: 'Health',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.history),
//               activeIcon: Icon(Icons.history),
//               label: 'History',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHomePage() {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16),
//       child: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Welcome Section
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.blue[400]!, Colors.blue[600]!],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.blue.withOpacity(0.3),
//                     blurRadius: 10,
//                     offset: Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.person,
//                           color: Colors.white,
//                           size: 24,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Welcome! Check on',
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             FutureBuilder<Map<String, dynamic>?>(
//                                 future: Firestoredatabase.getParentDetails(),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return Text(
//                                       'Loading...',
//                                       style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 24,
//                                           fontWeight: FontWeight.bold),
//                                       overflow: TextOverflow.ellipsis,
//                                     );
//                                   } else if (snapshot.hasData) {
//                                     final data = snapshot.data!;
//                                     return Text(
//                                       '${data['childName']}',
//                                       style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 24,
//                                           fontWeight: FontWeight.bold),
//                                       overflow: TextOverflow.ellipsis,
//                                     );
//                                   }
//                                   return Text(
//                                     'Child',
//                                     style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold),
//                                     overflow: TextOverflow.ellipsis,
//                                   );
//                                 })
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 16),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: _isInSafeZone ? Colors.green : Colors.red,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           _isInSafeZone ? Icons.check_circle : Icons.warning,
//                           color: Colors.white,
//                           size: 16,
//                         ),
//                         SizedBox(width: 6),
//                         Flexible(
//                           child: Text(
//                             _isInSafeZone ? 'Safe Zone' : 'Alert',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16),
//             const Text(
//               'Location',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//            FutureBuilder<Map<String, dynamic>?>(
//               future:
//               _getCurrentLocation(), // You'll need to implement this method
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Container(
//                     height: 200,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CircularProgressIndicator(
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(Colors.blue),
//                           ),
//                           SizedBox(height: 12),
//                           Text(
//                             'Loading location...',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }

//                 // Use actual location data if available, otherwise use defaults
//                 double? latitude = snapshot.data?['latitude'];
//                 double? longitude = snapshot.data?['longitude'];

//                 return MiniMapWidget(
//                   latitude: latitude,
//                   longitude: longitude,
//                   locationName: _currentLocation,
//                   isInSafeZone: _isInSafeZone,
//                 );
//               },
//             ),
//             SizedBox(height:10),
//             // Quick Status Cards - FIXED VERSION
//             Row(
//               children: [
//                 // Location Card
//                 Expanded(
//                   child: Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.green[100]!,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: Colors.green[600]!.withOpacity(0.2)),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Icon(
//                           Icons.location_on,
//                           size: 24,
//                           color: Colors.green[600]!,
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Location',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w500,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         SizedBox(height: 4),
//                         StreamBuilder<Position>(
//                           stream: locationService.getLocationStream(),
//                           builder: (context, snapshot) {
//                             if (snapshot.connectionState == ConnectionState.waiting) {
//                               return Text(
//                                 'Loading...',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               );
//                             }
                            
//                             if (snapshot.hasError) {
//                               return Text(
//                                 'Location error',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               );
//                             }
                            
//                             if (snapshot.hasData) {
//                               return FutureBuilder<String>(
//                                 future: _getLocationName(snapshot.data!),
//                                 builder: (context, locationSnapshot) {
//                                   if (locationSnapshot.connectionState == ConnectionState.waiting) {
//                                     return Text(
//                                       'Getting address...',
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.black87,
//                                       ),
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     );
//                                   }
                                  
//                                   return Text(
//                                     locationSnapshot.data ?? 'Unknown Location',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black87,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   );
//                                 },
//                               );
//                             }
                            
//                             return Text(
//                               'No location data',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 // Battery Card
//                 Expanded(
//                   child: _buildQuickStatusCard(
//                     title: 'Battery',
//                     value: _batteryLevel,
//                     icon: Icons.battery_full,
//                     color: Colors.orange[100]!,
//                     iconColor: Colors.orange[600]!,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),

//             // Health Metrics
//             const Text(
//               'Monitors',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 12),
//             Card(
//               color: Colors.white,
//               elevation: 0.5,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Activity Summary',
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.teal),
//                     ),
//                     const SizedBox(height: 10),
//                     ListTile(
//                       leading: const Icon(Icons.favorite, color: Colors.green),
//                       title: const Text('HRV: Normal (75%)'),
//                       subtitle: Text('Last updated: ${_formatCurrentTime()}'),
//                     ),
//                     ListTile(
//                       leading:
//                           const Icon(Icons.location_on, color: Colors.teal),
//                       title: const Text('Geofence: Active'),
//                       subtitle: Text('Radius: 200m'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: 20),

//             // Current Status
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.green[100],
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.psychology,
//                           color: Colors.green[600],
//                           size: 20,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Current Status',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 12),
//                   Text(
//                     _status,
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.grey[700],
//                       height: 1.4,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Last updated ${_formatCurrentTime()}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             SizedBox(height: 20),

//             // Geofencing Controls
//             const Text(
//               'Safety Controls',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 12),

//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: _isGeofencingEnabled
//                               ? Colors.blue[100]
//                               : Colors.grey[100],
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.location_searching,
//                           color: _isGeofencingEnabled
//                               ? Colors.blue[600]
//                               : Colors.grey[600],
//                           size: 24,
//                         ),
//                       ),
//                       SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Geofencing',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               _isGeofencingEnabled
//                                   ? 'Location monitoring is active'
//                                   : 'Location monitoring is disabled',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                       Switch(
//                         value: _isGeofencingEnabled,
//                         onChanged: (value) {
//                           setState(() {
//                             _isGeofencingEnabled = value;
//                           });
//                           HapticFeedback.lightImpact();
//                         },
//                         activeColor: Colors.blue,
//                         inactiveTrackColor: Colors.grey[300],
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             HapticFeedback.lightImpact();
//                             context.goNamed('placesSearchPage');
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                             padding: EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                           icon: Icon(Icons.edit_location, size: 18),
//                           label: Text(
//                             'Edit Safe Zone',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: () {
//                             HapticFeedback.lightImpact();
//                             setState(() {
//                               _selectedIndex = 1;
//                             });
//                           },
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: Colors.blue,
//                             padding: EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             side: BorderSide(color: Colors.blue, width: 1),
//                           ),
//                           icon: Icon(Icons.map, size: 18),
//                           label: Text(
//                             'View Map',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             SizedBox(height: 20),

//             // Quick Actions
//             Text(
//               'Quick Actions',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 12),

//             Row(
//               children: [
//                 Expanded(
//                   child: _buildQuickActionCard(
//                     title: 'Emergency',
//                     icon: Icons.emergency,
//                     color: Colors.red[100]!,
//                     iconColor: Colors.red[600]!,
//                     onTap: () {
//                       HapticFeedback.heavyImpact();
//                       context.goNamed('emergencyPage');
//                     },
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: _buildQuickActionCard(
//                     title: 'Find Device',
//                     icon: Icons.phone_android,
//                     color: Colors.purple[100]!,
//                     iconColor: Colors.purple[600]!,
//                     onTap: () {
//                       HapticFeedback.lightImpact();
//                     },
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: _buildQuickActionCard(
//                     title: 'Settings',
//                     icon: Icons.settings,
//                     color: Colors.grey[200]!,
//                     iconColor: Colors.grey[600]!,
//                     onTap: () {
//                       HapticFeedback.lightImpact();
//                       context.goNamed('manageCaregiversPage');
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 50), // Bottom padding for navigation
//           ],
//         ),
//       ),
//     );
//   }

//   Future<String> _getLocationName(Position position) async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude, 
//         position.longitude
//       );
      
//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         String locationName = "${place.locality ?? 'Unknown'}, ${place.country ?? 'Unknown'}";
//         return locationName;
//       }
//       return 'Unknown Location';
//     } catch (e) {
//       print("Error getting location name: $e");
//       return 'Location Error';
//     }
//   }

//   Widget _buildQuickStatusCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//     required Color iconColor,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: iconColor.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             size: 24,
//             color: iconColor,
//           ),
//           SizedBox(height: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//           SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActionCard({
//     required String title,
//     required IconData icon,
//     required Color color,
//     required Color iconColor,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: iconColor.withOpacity(0.2)),
//         ),
//         child: Column(
//           children: [
//             Icon(
//               icon,
//               size: 28,
//               color: iconColor,
//             ),
//             SizedBox(height: 8),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'dart:async';

// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';

// import 'GeofenceUtils.dart/geoManagementPage.dart';
// import 'healthMonitoring.dart';
// import 'mapScreen.dart';

// class HealthPage extends StatefulWidget {
//   const HealthPage({Key? key}) : super(key: key);

//   @override
//   State<HealthPage> createState() => _HealthPageState();
// }

// class _HealthPageState extends State<HealthPage> {
//   // Live values from Firebase
//   int _selectedIndex = 0;
//   double heartRate = 0.0;
//   int currentSteps = 0;
//   double caloriesBurned = 0.0;   // caloriesKcal
//   double distanceMeters = 0.0;

//   // Optional targets (static; adjust to your app’s logic)
//   int targetSteps = 5000;
//   double caloriesTarget = 320.0;

//   // Timestamp for "Updated:" label
//   DateTime? lastUpdated;

//   // Firebase (same approach as HRV page)
//   final DatabaseReference _healthRef =
//       FirebaseDatabase.instance.ref().child('test_write_health');
//   StreamSubscription<DatabaseEvent>? _sub;
//   StreamSubscription<DatabaseEvent>? _connSub;
//   bool _isConnected = false;

//   // Tiny HR trend (optional)
//   final List<FlSpot> _hrSpots = [];
//   int _hrIndex = 0;

//   // Sleep demo values (unchanged)
//   Duration deepSleep = const Duration(hours: 1, minutes: 45);
//   Duration lightSleep = const Duration(hours: 5, minutes: 10);
//   Duration timeAwake = const Duration(minutes: 23);
//   Duration totalSleep = const Duration(hours: 7, minutes: 58);

//   @override
//   void initState() {
//     super.initState();
//     _startFirebaseMonitoring(); // same style as HRV page
//   }

//   @override
//   void dispose() {
//     _sub?.cancel();
//     _connSub?.cancel();
//     super.dispose();
//   }

//   // === Same listening strategy as HRV page: one onValue on the collection node ===
//   void _startFirebaseMonitoring() {
//     // Connection state (optional but useful)
//     _connSub = FirebaseDatabase.instance
//         .ref('.info/connected')
//         .onValue
//         .listen((event) {
//       final connected = event.snapshot.value as bool? ?? false;
//       setState(() => _isConnected = connected);
//     });

//     // Stream the whole node and pull the latest child out of the map
//     _sub = _healthRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value;
//       if (data is! Map) return;

//       // Try to find the "latest" row.
//       // Prefer the one with the highest 'readingNumber'. If absent, use the last key.
//       Map<dynamic, dynamic>? latestRow;
//       int bestReading = -1;
//       String? lastKey;

//       for (final entry in data.entries) {
//         final k = entry.key;
//         final v = entry.value;
//         if (v is Map) {
//           // Track “last” key as a fallback
//           lastKey = k.toString();

//           // Prefer by readingNumber if present
//           final rnRaw = v['readingNumber'];
//           final rn = _toInt(rnRaw);
//           if (rn > bestReading) {
//             bestReading = rn;
//             latestRow = v.cast<dynamic, dynamic>();
//           }
//         }
//       }

//       // If no readingNumber found, fall back to last key in lexicographic order
//       latestRow ??= (lastKey != null) ? data[lastKey] as Map<dynamic, dynamic>? : null;
//       if (latestRow == null) return;

//       // Parse fields tolerantly (int/double/string/null)
//       final hr = _toDouble(latestRow['heartRate']);
//       final steps = _toInt(latestRow['steps']);
//       final meters = _toDouble(latestRow['distanceMeters']);
//       final kcal = _toDouble(latestRow['caloriesKcal']);

//       setState(() {
//         heartRate = hr;
//         currentSteps = steps;
//         distanceMeters = meters;
//         caloriesBurned = kcal;
//         lastUpdated = DateTime.now();

//         // update tiny trend
//         _hrSpots.add(FlSpot((_hrIndex++).toDouble(), hr));
//         if (_hrSpots.length > 30) _hrSpots.removeAt(0);
//       });
//     }, onError: (e) {
//       // If needed, you can surface an error UI state
//       debugPrint('HealthPage Firebase error: $e');
//     });
//   }

//   // ------- Parsing helpers (tolerate int/double/string/null) -------
//   int _toInt(dynamic x) {
//     if (x == null) return 0;
//     if (x is int) return x;
//     if (x is num) return x.toInt();
//     return int.tryParse(x.toString()) ?? 0;
//   }

//   double _toDouble(dynamic x) {
//     if (x == null) return 0.0;
//     if (x is double) return x;
//     if (x is num) return x.toDouble();
//     return double.tryParse(x.toString()) ?? 0.0;
//   }

//     Widget _getCurrentPage() {
//     switch (_selectedIndex) {
//       case 0:
//         return buildHomePage();
//       case 1:
//         return GeofencingMapsPage();
//       case 2:
//         return HRHRVMonitorPage();
//       case 3:
//         return GeofenceManagementPage();
//       default:
//         return buildHomePage();
//     }
//   }

//   // ------- UI -------
//   @override
//   Widget build(BuildContext context) {
//     final updatedText = lastUpdated == null ? '—' : _fmtTime(lastUpdated!);

//     return Scaffold(
//       backgroundColor: const Color(0xFFE8F4FD),
//       body: _getCurrentPage(),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//             HapticFeedback.lightImpact();
//           },
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.white,
//           selectedItemColor: Colors.blue,
//           unselectedItemColor: Colors.grey[600],
//           selectedLabelStyle:
//               TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//           unselectedLabelStyle: TextStyle(fontSize: 12),
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home_outlined),
//               activeIcon: Icon(Icons.home),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.location_on_outlined),
//               activeIcon: Icon(Icons.location_on),
//               label: 'Tracking',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.favorite_outline),
//               activeIcon: Icon(Icons.favorite),
//               label: 'Health',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.history),
//               activeIcon: Icon(Icons.history),
//               label: 'History',
//             ),
//           ],
//         ),
//       ), 
//     );
//   }

//   Widget buildHomePage(){
//     return SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header + connection pill
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Dashboard',
//                     style: TextStyle(
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       _connPill(_isConnected),
//                       const SizedBox(width: 12),
//                       IconButton(
//                         icon: const Icon(Icons.refresh, size: 22, color: Colors.black54),
//                         onPressed: () {
//                           _sub?.cancel();
//                           _startFirebaseMonitoring();
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // Heart Rate
//               _buildHeartRateCard(),

//               const SizedBox(height: 20),

//               // Steps + Calories
//               Row(
//                 children: [
//                   Expanded(child: _buildStepsCard()),
//                   const SizedBox(width: 16),
//                   Expanded(child: _buildCaloriesCard()),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // Distance
//               _buildDistanceCard(),

//               const SizedBox(height: 20),

//               // Bedtime
//               _buildBedtimeCard(),

//               const SizedBox(height: 20),

//               // Emergency SMS + Geofencing
//               Row(
//                 children: [
//                   Expanded(child: _buildEmergencySMSTab()),
//                   const SizedBox(width: 16),
//                   Expanded(child: _buildGeofencingTab()),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               _buildPersonalDataSection(),
//             ],
//           ),
//         ),
//       );
//   }
//   Widget _connPill(bool ok) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: ok ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: ok ? Colors.green : Colors.red),
//       ),
//       child: Row(
//         children: [
//           Icon(ok ? Icons.wifi : Icons.wifi_off, size: 14, color: ok ? Colors.green : Colors.red),
//           const SizedBox(width: 6),
//           Text(ok ? 'Connected' : 'Disconnected',
//               style: TextStyle(fontSize: 12, color: ok ? Colors.green : Colors.red)),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeartRateCard() {
//     final hasTrend = _hrSpots.length >= 2;

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _cardDeco(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               _iconBadge(Icons.favorite, Colors.red),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: const [
//                   Text(
//                     'Heart Rate',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   Text(
//                     'Your current BPM',
//                     style: TextStyle(fontSize: 12, color: Colors.black54),
//                   ),
//                 ],
//               ),
//               const Spacer(),
//               Text(
//                 heartRate.toStringAsFixed(0),
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               const Text(' bpm', style: TextStyle(color: Colors.black54)),
//             ],
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             height: 72,
//             child: hasTrend
//                 ? LineChart(
//                     LineChartData(
//                       gridData: FlGridData(show: false),
//                       titlesData: FlTitlesData(show: false),
//                       borderData: FlBorderData(show: false),
//                       lineBarsData: [
//                         LineChartBarData(
//                           spots: _hrSpots,
//                           isCurved: true,
//                           barWidth: 3,
//                           dotData: FlDotData(show: false),
//                           color: Colors.blue,
//                         ),
//                       ],
//                     ),
//                   )
//                 : Center(
//                     child: Text(
//                       'Waiting for data…',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepsCard() {
//     final progress = targetSteps == 0 ? 0.0 : currentSteps / targetSteps;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _cardDeco(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               Icon(Icons.directions_walk, color: Colors.blue, size: 20),
//               SizedBox(width: 8),
//               Text(
//                 'Steps',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const Text('Steps taken today',
//               style: TextStyle(fontSize: 10, color: Colors.black54)),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 72,
//             child: BarChart(
//               BarChartData(
//                 alignment: BarChartAlignment.spaceAround,
//                 maxY: (targetSteps == 0 ? 1 : targetSteps).toDouble(),
//                 barTouchData: BarTouchData(enabled: false),
//                 titlesData: FlTitlesData(show: false),
//                 borderData: FlBorderData(show: false),
//                 gridData: FlGridData(show: false),
//                 barGroups: List.generate(8, (i) {
//                   final v = (currentSteps * (0.7 + i * 0.05)).toDouble();
//                   return BarChartGroupData(
//                     x: i,
//                     barRods: [
//                       BarChartRodData(
//                         toY: v,
//                         color: Colors.blue.withOpacity(0.85),
//                         width: 8,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ],
//                   );
//                 }),
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: progress.clamp(0.0, 1.0),
//             minHeight: 6,
//             backgroundColor: Colors.grey[200],
//             color: Colors.blue,
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _kv('Current', '$currentSteps'),
//               _kv('Target', '$targetSteps'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCaloriesCard() {
//     final progress = caloriesTarget == 0
//         ? 0.0
//         : (caloriesBurned / caloriesTarget).clamp(0.0, 1.0);

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _cardDeco(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
//               SizedBox(width: 8),
//               Text(
//                 'Calories',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const Text('Calories burned',
//               style: TextStyle(fontSize: 10, color: Colors.black54)),
//           const SizedBox(height: 12),
//           Center(
//             child: SizedBox(
//               width: 80,
//               height: 80,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     value: progress,
//                     strokeWidth: 8,
//                     backgroundColor: Colors.grey[200],
//                     valueColor:
//                         const AlwaysStoppedAnimation<Color>(Colors.blue),
//                   ),
//                   Text(
//                     caloriesBurned.toStringAsFixed(2),
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _kv('Calories', '${caloriesBurned.toStringAsFixed(2)} kcal'),
//               _kv('Target', '${caloriesTarget.toStringAsFixed(0)} kcal'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDistanceCard() {
//     final String distanceText = distanceMeters >= 1000
//         ? '${(distanceMeters / 1000).toStringAsFixed(2)} km'
//         : '${distanceMeters.toStringAsFixed(2)} m';

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _cardDeco(),
//       child: Row(
//         children: [
//           _iconBadge(Icons.route, Colors.green, radius: 12),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text(
//                 'Distance',
//                 style: TextStyle(
//                     fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
//               ),
//               Text('Total distance covered',
//                   style: TextStyle(fontSize: 12, color: Colors.black54)),
//             ],
//           ),
//           const Spacer(),
//           Text(
//             distanceText,
//             style: const TextStyle(
//                 fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBedtimeCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _cardDeco(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               _iconBadge(Icons.bedtime, Colors.purple),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: const [
//                   Text(
//                     'Bedtime',
//                     style: TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
//                   ),
//                   Text('Track your sleep routine',
//                       style: TextStyle(fontSize: 12, color: Colors.black54)),
//                 ],
//               ),
//               const Spacer(),
//               Text(
//                 '${totalSleep.inHours}h ${totalSleep.inMinutes.remainder(60)}m',
//                 style: const TextStyle(
//                     fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               _sleepStat('Deep sleep', deepSleep, Colors.blue),
//               const SizedBox(width: 20),
//               _sleepStat('Light sleep', lightSleep, Colors.lightBlue),
//               const SizedBox(width: 20),
//               _sleepStat('Time awake', timeAwake, Colors.orange),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmergencySMSTab() {
//     return GestureDetector(
//       onTap: () => context.goNamed('emergencyPage'),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.red.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.red.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             const Icon(Icons.emergency, color: Colors.red, size: 32),
//             const SizedBox(height: 8),
//             const Text(
//               'Emergency SMS',
//               style: TextStyle(
//                   fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
//             ),
//             Text(
//               'Quick emergency alerts',
//               style:
//                   TextStyle(fontSize: 10, color: Colors.red.withOpacity(0.7)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGeofencingTab() {
//     return GestureDetector(
//       onTap: () => context.goNamed('placesSearchPage'),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.green.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.green.withOpacity(0.3)),
//         ),
//         child: Column(
//           children: [
//             const Icon(Icons.location_on, color: Colors.green, size: 32),
//             const SizedBox(height: 8),
//             const Text(
//               'Geofencing',
//               style: TextStyle(
//                   fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
//             ),
//             Text(
//               'Location boundaries',
//               style: TextStyle(
//                   fontSize: 10, color: Colors.green.withOpacity(0.7)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPersonalDataSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _cardDeco(),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: const [
//           Text(
//             'Personal Data',
//             style: TextStyle(
//                 fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
//           ),
//           Row(
//             children: [
//               Text('see more', style: TextStyle(color: Colors.black54)),
//               SizedBox(width: 4),
//               Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ------- Small UI helpers -------
//   BoxDecoration _cardDeco() => BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       );

//   Widget _iconBadge(IconData icon, Color color, {double radius = 8}) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(radius),
//       ),
//       child: Icon(icon, color: color, size: 20),
//     );
//   }

//   Widget _kv(String k, String v) => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(k, style: const TextStyle(fontSize: 10, color: Colors.black54)),
//           Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//         ],
//       );

//   Widget _sleepStat(String label, Duration d, Color color) {
//     return Column(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration:
//               BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
//         Text(
//           '${d.inHours}h ${d.inMinutes.remainder(60)}m',
//           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//         ),
//       ],
//     );
//   }

//   String _fmtTime(DateTime t) {
//     final hh = t.hour.toString().padLeft(2, '0');
//     final mm = t.minute.toString().padLeft(2, '0');
//     return '$hh:$mm';
//   }
// }

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'GeofenceUtils.dart/geoManagementPage.dart';
import 'healthMonitoring.dart';
import 'mapScreen.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({Key? key}) : super(key: key);

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // Live values from Firebase
  int _selectedIndex = 0;
  double heartRate = 0.0;
  int currentSteps = 0;
  double caloriesBurned = 0.0;   // caloriesKcal
  double distanceMeters = 0.0;

  // Optional targets (static; adjust to your app's logic)
  int targetSteps = 5000;
  double caloriesTarget = 320.0;

  // Timestamp for "Updated:" label
  DateTime? lastUpdated;

  // Firebase - same approach as HRV page
  final DatabaseReference _healthRef =
      FirebaseDatabase.instance.ref().child('test_write_health');
  StreamSubscription<DatabaseEvent>? _sub;
  StreamSubscription<DatabaseEvent>? _connSub;
  bool _isConnected = false;

  // Connection status timer
  Timer? _connectionTimer;

  // Tiny HR trend (optional)
  final List<FlSpot> _hrSpots = [];
  int _hrIndex = 0;

  // Sleep demo values (unchanged)
  Duration deepSleep = const Duration(hours: 1, minutes: 45);
  Duration lightSleep = const Duration(hours: 5, minutes: 10);
  Duration timeAwake = const Duration(minutes: 23);
  Duration totalSleep = const Duration(hours: 7, minutes: 58);

  @override
  void initState() {
    super.initState();
    _startFirebaseMonitoring();
    _startConnectionTimer();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connSub?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }

  void _startConnectionTimer() {
    // Timer to check connection status - same as HRV page
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (lastUpdated != null) {
        final timeSinceLastUpdate = DateTime.now().difference(lastUpdated!).inSeconds;
        setState(() {
          _isConnected = timeSinceLastUpdate < 30; // Consider disconnected if no data for 30 seconds
        });
      }
    });
  }

  // Same listening strategy as HRV page - using the exact same approach
  void _startFirebaseMonitoring() {
    print('HealthPage: Starting Firebase monitoring...');
    
    // Listen to the entire test_write_health node to catch all device updates - same as HRV page
    _sub = _healthRef.onValue.listen(
      (DatabaseEvent event) {
        print('HealthPage: Firebase data received: ${event.snapshot.value}');
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          _processFirebaseData(data);
        }
      },
      onError: (error) {
        print('HealthPage: Firebase listening error: $error');
        setState(() {
          _isConnected = false;
        });
      },
    );

    // Also listen to Firebase connection state - same as HRV page
    FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      print('HealthPage: Firebase connection state: $connected');
      if (!connected) {
        setState(() {
          _isConnected = false;
        });
      }
    });
  }

  void _processFirebaseData(Map<dynamic, dynamic> data) {
    print('HealthPage: Processing Firebase data: $data');
    
    // Look for device entries in the data - same approach as HRV page
    data.forEach((key, value) {
      if (value is Map) {
        final deviceData = value as Map<dynamic, dynamic>;
        print('HealthPage: Found device data for key $key: $deviceData');
        
        // Process this device's data
        _processDeviceData(deviceData, key.toString());
      }
    });
  }

  void _processDeviceData(Map<dynamic, dynamic> deviceData, String key) {
    // Extract all the health metrics from this device data
    final heartRateRaw = deviceData['heartRate'];
    final stepsRaw = deviceData['steps'];
    final caloriesRaw = deviceData['caloriesKcal'];
    final distanceRaw = deviceData['distanceMeters'];
    final deviceId = deviceData['deviceId']?.toString() ?? 'Unknown';
    final readingNumber = deviceData['readingNumber'];
    
    print('HealthPage: Processing device data - HR: $heartRateRaw, Steps: $stepsRaw, Calories: $caloriesRaw, Distance: $distanceRaw');
    
    final now = DateTime.now();
    
    setState(() {
      // Update heart rate
      if (heartRateRaw is num) {
        heartRate = heartRateRaw.toDouble();
        
        // Add to HR trend
        _hrSpots.add(FlSpot((_hrIndex++).toDouble(), heartRate));
        if (_hrSpots.length > 30) _hrSpots.removeAt(0);
      }
      
      // Update steps
      if (stepsRaw is num) {
        currentSteps = stepsRaw.toInt();
      }
      
      // Update calories
      if (caloriesRaw is num) {
        caloriesBurned = caloriesRaw.toDouble();
      }
      
      // Update distance
      if (distanceRaw is num) {
        distanceMeters = distanceRaw.toDouble();
      }
      
      // Update connection status
      lastUpdated = now;
      _isConnected = true;
      
      print('HealthPage: Updated values - HR: $heartRate, Steps: $currentSteps, Calories: $caloriesBurned, Distance: $distanceMeters');
    });
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return buildHomePage();
      case 1:
        return GeofencingMapsPage();
      case 2:
        return HRHRVMonitorPage();
      case 3:
        return GeofenceManagementPage();
      default:
        return buildHomePage();
    }
  }

  // ------- UI -------
  @override
  Widget build(BuildContext context) {
    final updatedText = lastUpdated == null ? '—' : _fmtTime(lastUpdated!);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            HapticFeedback.lightImpact();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ), 
    );
  }

  Widget buildHomePage(){
    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + connection pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue
                    ),
                  ),
                  Row(
                    children: [
                      _connPill(_isConnected),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 22, color: Colors.black54),
                        onPressed: () {
                          _sub?.cancel();
                          _startFirebaseMonitoring();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              
              // Debug info row
              if (lastUpdated != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Last updated: ${_fmtTime(lastUpdated!)} | HR: ${heartRate.toInt()} | Steps: $currentSteps | Cal: ${caloriesBurned.toStringAsFixed(1)} | Dist: ${distanceMeters.toStringAsFixed(1)}m',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),

              const SizedBox(height: 20),

              // Heart Rate
              _buildHeartRateCard(),

              const SizedBox(height: 20),

              // Steps + Calories
              Row(
                children: [
                  Expanded(child: _buildStepsCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCaloriesCard()),
                ],
              ),

              const SizedBox(height: 20),

              // Distance
              _buildDistanceCard(),

              const SizedBox(height: 20),

              // Bedtime
              _buildBedtimeCard(),

              const SizedBox(height: 20),

              // Emergency SMS + Geofencing
              Row(
                children: [
                  Expanded(child: _buildEmergencySMSTab()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGeofencingTab()),
                ],
              ),

              const SizedBox(height: 20),

              _buildPersonalDataSection(),
            ],
          ),
        ),
      );
  }
  
  Widget _connPill(bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ok ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.wifi : Icons.wifi_off, size: 14, color: ok ? Colors.green : Colors.red),
          const SizedBox(width: 6),
          Text(ok ? 'Connected' : 'Disconnected',
              style: TextStyle(fontSize: 12, color: ok ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    final hasTrend = _hrSpots.length >= 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBadge(Icons.favorite, Colors.red),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Heart Rate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Child\'s current BPM',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                heartRate > 0 ? heartRate.toStringAsFixed(0) : '--',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? Colors.black : Colors.grey,
                ),
              ),
              const Text(' bpm', style: TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 72,
            child: hasTrend
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _hrSpots,
                          isCurved: true,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Waiting for data…',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    final progress = targetSteps == 0 ? 0.0 : currentSteps / targetSteps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.directions_walk, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Text('Steps taken today',
              style: TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (targetSteps == 0 ? 1 : targetSteps).toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: List.generate(8, (i) {
                  final v = (currentSteps * (0.7 + i * 0.05)).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        color: Colors.blue.withOpacity(0.85),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv('Current', '$currentSteps'),
              _kv('Target', '$targetSteps'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    final progress = caloriesTarget == 0
        ? 0.0
        : (caloriesBurned / caloriesTarget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Calories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Text('Calories burned',
              style: TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  Text(
                    caloriesBurned > 0 ? caloriesBurned.toStringAsFixed(1) : '--',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv('Calories', caloriesBurned > 0 ? '${caloriesBurned.toStringAsFixed(1)} kcal' : '-- kcal'),
              _kv('Target', '${caloriesTarget.toStringAsFixed(0)} kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard() {
    final String distanceText = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(2)} km'
        : distanceMeters > 0 
            ? '${distanceMeters.toStringAsFixed(2)} m'
            : '-- m';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Row(
        children: [
          _iconBadge(Icons.route, Colors.green, radius: 12),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Distance',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              Text('Total distance covered',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          Text(
            distanceText,
            style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: _isConnected && distanceMeters > 0 ? Colors.black : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBedtimeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBadge(Icons.bedtime, Colors.purple),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Child status',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  Text('Child is in an amused state',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
              const Spacer(),
              Text(
                '${totalSleep.inHours}h ${totalSleep.inMinutes.remainder(60)}m',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _sleepStat('Deep sleep', deepSleep, Colors.blue),
              const SizedBox(width: 20),
              _sleepStat('Light sleep', lightSleep, Colors.green),
              const SizedBox(width: 20),
              _sleepStat('Time awake', timeAwake, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySMSTab() {
    return GestureDetector(
      onTap: () => context.goNamed('emergencyPage'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.emergency, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Emergency SMS',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
            ),
            Text(
              'Quick emergency alerts',
              style:
                  TextStyle(fontSize: 10, color: Colors.red.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofencingTab() {
    return GestureDetector(
      onTap: () => context.goNamed('placesSearchPage'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Geofencing',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
            ),
            Text(
              'Location boundaries',
              style: TextStyle(
                  fontSize: 10, color: Colors.green.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child:  Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Personal Data',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          Row(
            children: [
              GestureDetector(
                onTap:()=> context.goNamed('manageCaregiversPage.dart'),
                child: Text('see more', style: TextStyle(color: Colors.black54))),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
            ],
          ),
        ],
      ),
    );
  }

  // ------- Small UI helpers -------
  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _iconBadge(IconData icon, Color color, {double radius = 8}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _sleepStat(String label, Duration d, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        Text(
          '${d.inHours}h ${d.inMinutes.remainder(60)}m',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _fmtTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}