
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
// import 'package:geolocator/geolocator.dart';

// class Location {
//   double? latitude;
//   double? longitude;

//   Future<void> getCurrentLocation() async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.deniedForever) {
//         return Future.error('Location permissions are permanently denied.');
//       }
//       Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       latitude = position.latitude;
//       longitude = position.longitude;
//       print(position);
//     } catch (e) {
//       print("Error getting location: $e");
//     }
//   }

//   Future<dynamic> getLocationName() async {
//     await getCurrentLocation();
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(latitude!, longitude!);
//       Placemark place = placemarks[0];
//       String locationName = "${place.locality}, ${place.country}";
//  //     print("Location Name: $locationName"); // Print: Los Angeles, USA
//      return  locationName;
//     } catch (e) {
//       print("Error: $e");
//       return 'Unknown Location';
//     }
//   }
// }


import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  double? latitude;
  double? longitude;
  DateTime? lastUpdated;

  // Enhanced getCurrentLocation method
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10), // Add timeout
      );

      // Update instance variables
      latitude = position.latitude;
      longitude = position.longitude;
      lastUpdated = DateTime.now();

      print("Location updated: $latitude, $longitude");

      // Return formatted data for the mini map
      return {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': position.accuracy,
        'timestamp': lastUpdated!.toIso8601String(),
        'speed': position.speed,
        'heading': position.heading,
      };
    } catch (e) {
      print("Error getting location: $e");
      
      // Return fallback location (Accra, Ghana) if location fails
      return {
        'latitude': 5.6037,
        'longitude': -0.1870,
        'accuracy': null,
        'timestamp': DateTime.now().toIso8601String(),
        'speed': null,
        'heading': null,
        'error': e.toString(),
      };
    }
  }

  // Enhanced setLocation method for your dashboard
  Future<void> setLocation(Function? onLocationUpdate) async {
    try {
      final locationData = await getCurrentLocation();
      
      if (locationData != null) {
        final lat = locationData['latitude'] as double;
        final lng = locationData['longitude'] as double;
        
        // Create LatLng for Google Maps
        LatLng currentLocation = LatLng(lat, lng);
        
        // Create marker for current location
        Marker currentLocationMarker = Marker(
          markerId: const MarkerId("currentLocation"),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: "Current Location",
            snippet: "Updated: ${_formatTime(lastUpdated)}",
          ),
        );

        // Call the callback to update UI
        if (onLocationUpdate != null) {
          onLocationUpdate(currentLocation, currentLocationMarker, locationData);
        }
      }
    } catch (e) {
      print("Error in setLocation: $e");
    }
  }

  // Method to get location stream for real-time updates
   Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  // Check if location data is recent (within last 5 minutes)
  bool isLocationFresh() {
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated!).inMinutes < 5;
  }

  // Get cached location if available and fresh
  Map<String, dynamic>? getCachedLocation() {
    if (latitude != null && longitude != null && isLocationFresh()) {
      return {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': lastUpdated!.toIso8601String(),
        'cached': true,
      };
    }
    return null;
  }

  // Format time for display
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return "Unknown";
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hr ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }
}

