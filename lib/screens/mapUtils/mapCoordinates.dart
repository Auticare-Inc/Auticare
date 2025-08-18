
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class Locations {
  double? latitude;
  double? longitude;

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location permissions are permanently denied.');
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      latitude = position.latitude;
      longitude = position.longitude;
      print(position);
    } catch (e) {
      ScaffoldMessenger(child:SnackBar(content: Text('Error getting location:$e')));
    }
  }

  Future<dynamic> getLocationName() async {
    await getCurrentLocation();
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude!, longitude!);
      Placemark place = placemarks[0];
      String locationName = "${place.locality}, ${place.country}";
 //     print("Location Name: $locationName"); // Print: Los Angeles, USA
     return  locationName;
    } catch (e) {
      return ScaffoldMessenger(child:SnackBar(content: Text('Error:$e')));
    }
  }
}


