/*import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Geofencing {
final LatLng safeZoneCenter = LatLng(5.6037, -0.1870); // Accra
final double safeZoneRadius = 200; // meters

double calculateDistance(LatLng point1, LatLng point2) {
  const earthRadius = 6371000; // meters
  double dLat = (point2.latitude - point1.latitude) * pi / 180;
  double dLng = (point2.longitude - point1.longitude) * pi / 180;
  double a = sin(dLat/2) * sin(dLat/2) +
      cos(point1.latitude * pi / 180) * cos(point2.latitude * pi / 180) *
      sin(dLng/2) * sin(dLng/2);
  double c = 2 * atan2(sqrt(a), sqrt(1-a));
  return earthRadius * c;
}

bool isOutsideSafeZone(LatLng currentLocation) {
  double distance = calculateDistance(currentLocation, safeZoneCenter);
  return distance > safeZoneRadius;
}

void sendExitAlert(Position pos){
  DatabaseReference ref = DatabaseReference.instance.ref('alerts/user123');
  ref.set({
    'status':'out of bounds',
    'lat': pos.latitude,
    'lon': pos.longitude,
    'TimeStamp': DateTime.now().toIso8601String()
});
}


void startTracking(){
  Geolocator.getPositionStream().listen((Position position){
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude, 
      safeZoneCenter.latitude, 
      safeZoneCenter.longitude
      );
    if(distance>safeZoneRadius){
      sendExitAlert(position);
    }
  });  
}
} */