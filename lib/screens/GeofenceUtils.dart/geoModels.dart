import 'package:flutter/material.dart';

import '../../models/place.dart';

class Geofence {
  final String id;
  final String placeId;
  final String placeName;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final GeofenceType type;

  Geofence(
     {
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    this.radius = 250.0, // Default 100 meters
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
    this.type = GeofenceType.both, 
  });

  // Create geofence from Place
  factory Geofence.fromPlace(Place place) {
    final now = DateTime.now();
    return Geofence(
      // id: 'geofence_${place.id}_${now.millisecondsSinceEpoch}',
      id: 'geofence_${place.id}',
      placeId: place.id,
      placeName: place.name,
      latitude: place.latitude,
      longitude: place.longitude,
      startTime: place.startTime,
      endTime: place.endTime,
      createdAt: now,
      expiresAt: now.add(Duration(hours: 24)),
    );
  }

  // Check if geofence is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Check if current time is within the scheduled time window (±1 minute)
  bool isWithinTimeWindow(TimeOfDay currentTime) {
    final now = DateTime.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Check start time (±1 minute)
    if ((currentMinutes >= startMinutes - 1 && currentMinutes <= startMinutes + 1)) {
      return true;
    }

    // Check end time (±1 minute)
    if ((currentMinutes >= endMinutes - 1 && currentMinutes <= endMinutes + 1)) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'placeName': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
      'type': type.toString(),
    };
  }

  factory Geofence.fromJson(Map<String, dynamic> json) {
    final startTimeParts = json['startTime'].toString().split(':');
    final endTimeParts = json['endTime'].toString().split(':');

    return Geofence(
      id: json['id'],
      placeId: json['placeId'],
      placeName: json['placeName'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      radius: json['radius']?.toDouble() ?? 100.0,
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      isActive: json['isActive'] ?? true,
      type: GeofenceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => GeofenceType.both,
      ),
    );
  }
}

enum GeofenceType { entry, exit, both }
