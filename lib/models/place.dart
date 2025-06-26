import 'package:flutter/material.dart';

class Place {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isActive;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  Place copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }
}