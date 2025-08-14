import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/place.dart';
import 'geoModels.dart';
import '../GeofenceUtils.dart/geoStorage.dart';

class EnhancedGeofencingService {
  static final EnhancedGeofencingService _instance =
      EnhancedGeofencingService._internal();
  factory EnhancedGeofencingService() => _instance;
  EnhancedGeofencingService._internal();

  final List<Geofence> _activeGeofences = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, GeofenceStatus> _geofenceStatuses = {};

  // Firebase integration
  StreamSubscription<DatabaseEvent>? _firebaseSubscription;
  StreamSubscription<Position>? _positionStream;

  // Child location tracking
  LatLng? _childLocation;
  Timer? _cleanupTimer;
  final Map<String, DateTime> _lastAbsentAlert = {};
  static const Duration _absentCooldown = Duration(minutes: 2);

  // Callbacks for UI updates
  Function(List<Geofence>)? onGeofencesUpdated;
  Function(String geofenceId, bool isInside)? onGeofenceStatusChanged;
  Function(LatLng location)? onChildLocationUpdated;

  List<Geofence> get activeGeofences => List.unmodifiable(_activeGeofences);
  Map<String, GeofenceStatus> get geofenceStatuses =>
      Map.unmodifiable(_geofenceStatuses);
  LatLng? get childLocation => _childLocation;
  // at the top of the class (fields)
  Timer? _pollTimer;
  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _checkAllGeofences());
  }

  Future<void> initialize() async {
    await _initializeNotifications();
    await _loadSavedGeofences();
    _startFirebaseLocationListener();
    _startLocationTracking();
    _startCleanupTimer();
    _startPollTimer();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);
  }


  Future<void> _loadSavedGeofences() async {
    final saved = await StorageService.getGeofences();
    _activeGeofences.clear();
    _activeGeofences.addAll(saved.where((g) => !g.isExpired && g.isActive));
    for (final geofence in _activeGeofences) {
      _geofenceStatuses[geofence.id] = GeofenceStatus.unknown;
      print(
          'Loaded geofence: ${geofence.placeName}, lat: ${geofence.latitude}, lng: ${geofence.longitude}');
    }
    onGeofencesUpdated?.call(_activeGeofences);
  }

  Future<List<Place>> getPlaces() async {
    final geofences = await StorageService.getGeofences();
    return geofences
        .map((geofence) => Place(
              id: geofence.placeId,
              name: geofence.placeName,
              address: '', // Address may need to be stored separately
              latitude: geofence.latitude,
              longitude: geofence.longitude,
              startTime: geofence.startTime,
              endTime: geofence.endTime,
            ))
        .toList();
  }

  Future<void> _saveGeofences() async {
    await StorageService.saveGeofences(_activeGeofences);
  }

  void _startFirebaseLocationListener() {
    final ref = FirebaseDatabase.instance.ref('test_write/location');

    _firebaseSubscription = ref.limitToLast(1).onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(
            event.snapshot.children.first.value as Map);

        double latitude = data['latitude'];
        double longitude = data['longitude'];

        _childLocation = LatLng(latitude, longitude);
        onChildLocationUpdated?.call(_childLocation!);

        // Check all geofences when location updates
        _checkAllGeofences();
      }
    });
  }

  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      // Fallback to device location if Firebase not available
      if (_childLocation == null) {
        _childLocation = LatLng(position.latitude, position.longitude);
        onChildLocationUpdated?.call(_childLocation!);
        _checkAllGeofences();
      }
    });
  }

  void _checkAllGeofences() async {
    if (_childLocation == null) return;

    final currentTime = TimeOfDay.now();

    for (final geofence in _activeGeofences) {
      if (!geofence.isActive || geofence.isExpired) continue;

      final distance = Geolocator.distanceBetween(
        _childLocation!.latitude,
        _childLocation!.longitude,
        geofence.latitude,
        geofence.longitude,
      );

      final isInside = distance <= geofence.radius;
      final isWithinTimeWindow = geofence.isWithinTimeWindow(currentTime);
      final previousStatus = _geofenceStatuses[geofence.id];

      GeofenceStatus newStatus;
      if (isInside && isWithinTimeWindow) {
        newStatus = GeofenceStatus.insideOnTime;
      } else if (isInside && !isWithinTimeWindow) {
        newStatus = GeofenceStatus.insideOffTime;
      } else if (!isInside && isWithinTimeWindow) {
        newStatus = GeofenceStatus.outsideOnTime;
      } else {
        newStatus = GeofenceStatus.outsideOffTime;
      }

      _geofenceStatuses[geofence.id] = newStatus;

      // Notify UI of status change
      if (previousStatus != newStatus) {
        onGeofenceStatusChanged?.call(geofence.id, isInside);

        // Trigger notifications for important events
        if (isWithinTimeWindow) {
          if (isInside && previousStatus != GeofenceStatus.insideOnTime) {
            _triggerGeofenceEvent(geofence, GeofenceEvent.enter);
          } else if (!isInside &&
              previousStatus == GeofenceStatus.insideOnTime) {
            _triggerGeofenceEvent(geofence, GeofenceEvent.exit);
          }
        }
      }
      // Alert when the child is outside during the active window (even if they never entered)
      if (isWithinTimeWindow && !isInside) {
        final last = _lastAbsentAlert[geofence.id];
        final ok =
            last == null || DateTime.now().difference(last) >= _absentCooldown;
        if (ok) {
          await _showNotification(
            'Geofence Alert - Absent',
            'Child should be at ${geofence.placeName} now',
          );
          _lastAbsentAlert[geofence.id] = DateTime.now();
        }
      }
    }
  }

  Future<void> _triggerGeofenceEvent(
      Geofence geofence, GeofenceEvent event) async {
    String title;
    String body;

    switch (event) {
      case GeofenceEvent.enter:
        title = 'Geofence Entry';
        body = 'Child has arrived at ${geofence.placeName}';
        break;
      case GeofenceEvent.exit:
        title = 'Geofence Exit';
        body = 'Child has left ${geofence.placeName}';
        break;
      case GeofenceEvent.dwell:
        title = 'Geofence Dwelling';
        body = 'Child is staying at ${geofence.placeName}';
        break;
    }

    await _showNotification(title, body);
    print('Geofence event: $event for ${geofence.placeName}');
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Notifications',
      channelDescription: 'Notifications for geofence events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _cleanupExpiredGeofences();
    });
  }

  void _cleanupExpiredGeofences() {
    final initialCount = _activeGeofences.length;
    _activeGeofences.removeWhere((geofence) => geofence.isExpired);

    if (_activeGeofences.length != initialCount) {
      _saveGeofences();
      onGeofencesUpdated?.call(_activeGeofences);
    }
  }

  Future<void> createGeofenceFromPlace(Place place) async {
    // final existingGeofence = _activeGeofences.firstWhere(
    //   (g) => g.placeId == place.id,
    //   orElse: () => null,
    // );
    if (_activeGeofences.any((g) => g.id == 'geofence_${place.id}')) {
      return; // Don't create duplicate
    }

    final geofence = Geofence.fromPlace(place);
    _activeGeofences.add(geofence);
    _geofenceStatuses[geofence.id] = GeofenceStatus.unknown;

    await _saveGeofences();
    onGeofencesUpdated?.call(_activeGeofences);

    // Check the new geofence immediately
    if (_childLocation != null) {
      _checkAllGeofences();
    }
  }

  Future<void> removeGeofence(String geofenceId) async {
    _activeGeofences.removeWhere((g) => g.id == geofenceId);
    _geofenceStatuses.remove(geofenceId);

    await _saveGeofences();
    onGeofencesUpdated?.call(_activeGeofences);
  }

  Future<void> removeGeofencesForPlace(String placeId) async {
    final removedGeofences =
        _activeGeofences.where((g) => g.placeId == placeId).toList();

    for (final geofence in removedGeofences) {
      _geofenceStatuses.remove(geofence.id);
    }

    _activeGeofences.removeWhere((g) => g.placeId == placeId);

    await _saveGeofences();
    onGeofencesUpdated?.call(_activeGeofences);
  }

  Future<void> updateGeofenceRadius(String geofenceId, double newRadius) async {
    final geofenceIndex =
        _activeGeofences.indexWhere((g) => g.id == geofenceId);
    if (geofenceIndex == -1) return;

    // Create updated geofence with new radius
    final oldGeofence = _activeGeofences[geofenceIndex];
    final updatedGeofence = Geofence(
      id: oldGeofence.id,
      placeId: oldGeofence.placeId,
      placeName: oldGeofence.placeName,
      latitude: oldGeofence.latitude,
      longitude: oldGeofence.longitude,
      radius: newRadius,
      startTime: oldGeofence.startTime,
      endTime: oldGeofence.endTime,
      createdAt: oldGeofence.createdAt,
      expiresAt: oldGeofence.expiresAt,
      isActive: oldGeofence.isActive,
      type: oldGeofence.type,
    );

    _activeGeofences[geofenceIndex] = updatedGeofence;
    await _saveGeofences();
    onGeofencesUpdated?.call(_activeGeofences);

    // Re-check geofences after radius update
    if (_childLocation != null) {
      _checkAllGeofences();
    }
  }

  Future<void> updateGeofenceTimeWindow(
      String geofenceId, TimeOfDay startTime, TimeOfDay endTime) async {
    final geofenceIndex =
        _activeGeofences.indexWhere((g) => g.id == geofenceId);
    if (geofenceIndex == -1) return;

    final oldGeofence = _activeGeofences[geofenceIndex];
    final updatedGeofence = Geofence(
      id: oldGeofence.id,
      placeId: oldGeofence.placeId,
      placeName: oldGeofence.placeName,
      latitude: oldGeofence.latitude,
      longitude: oldGeofence.longitude,
      radius: oldGeofence.radius,
      startTime: startTime,
      endTime: endTime,
      createdAt: oldGeofence.createdAt,
      expiresAt: oldGeofence.expiresAt,
      isActive: oldGeofence.isActive,
      type: oldGeofence.type,
    );

    _activeGeofences[geofenceIndex] = updatedGeofence;
    await _saveGeofences();
    onGeofencesUpdated?.call(_activeGeofences);

    // Re-check geofences after time window update
    if (_childLocation != null) {
      _checkAllGeofences();
    }
  }

  Future<void> toggleGeofenceStatus(String geofenceId, bool isActive) async {
    final geofenceIndex =
        _activeGeofences.indexWhere((g) => g.id == geofenceId);
    if (geofenceIndex == -1) return;

    final oldGeofence = _activeGeofences[geofenceIndex];
    final updatedGeofence = Geofence(
      id: oldGeofence.id,
      placeId: oldGeofence.placeId,
      placeName: oldGeofence.placeName,
      latitude: oldGeofence.latitude,
      longitude: oldGeofence.longitude,
      radius: oldGeofence.radius,
      startTime: oldGeofence.startTime,
      endTime: oldGeofence.endTime,
      createdAt: oldGeofence.createdAt,
      expiresAt: oldGeofence.expiresAt,
      isActive: isActive,
      type: oldGeofence.type,
    );

    _activeGeofences[geofenceIndex] = updatedGeofence;
    await _saveGeofences();
    onGeofencesUpdated?.call(_activeGeofences);

    if (isActive && _childLocation != null) {
      _checkAllGeofences();
    }
  }

  Future<void> extendGeofenceExpiry(
      String geofenceId, Duration extension) async {
    final geofenceIndex =
        _activeGeofences.indexWhere((g) => g.id == geofenceId);
    if (geofenceIndex == -1) return;

    final oldGeofence = _activeGeofences[geofenceIndex];
    final updatedGeofence = Geofence(
      id: oldGeofence.id,
      placeId: oldGeofence.placeId,
      placeName: oldGeofence.placeName,
      latitude: oldGeofence.latitude,
      longitude: oldGeofence.longitude,
      radius: oldGeofence.radius,
      startTime: oldGeofence.startTime,
      endTime: oldGeofence.endTime,
      createdAt: oldGeofence.createdAt,
      expiresAt: oldGeofence.expiresAt.add(extension),
      isActive: oldGeofence.isActive,
      type: oldGeofence.type,
    );

    _activeGeofences[geofenceIndex] = updatedGeofence;
    await _saveGeofences();
    onGeofencesUpdated?.call(_activeGeofences);
  }

  // Get geofence status for a specific geofence
  GeofenceStatus? getGeofenceStatus(String geofenceId) {
    return _geofenceStatuses[geofenceId];
  }

  // Get all geofences for a specific place
  List<Geofence> getGeofencesForPlace(String placeId) {
    return _activeGeofences.where((g) => g.placeId == placeId).toList();
  }

  // Get distance to a specific geofence
  double? getDistanceToGeofence(String geofenceId) {
    if (_childLocation == null) return null;

    final geofence = _activeGeofences.firstWhere(
      (g) => g.id == geofenceId,
      orElse: () => throw Exception('Geofence not found'),
    );

    return Geolocator.distanceBetween(
      _childLocation!.latitude,
      _childLocation!.longitude,
      geofence.latitude,
      geofence.longitude,
    );
  }

  // Get all geofences within a certain distance
  List<Geofence> getNearbyGeofences(double maxDistance) {
    if (_childLocation == null) return [];

    return _activeGeofences.where((geofence) {
      final distance = Geolocator.distanceBetween(
        _childLocation!.latitude,
        _childLocation!.longitude,
        geofence.latitude,
        geofence.longitude,
      );
      return distance <= maxDistance;
    }).toList();
  }

  // Force refresh all geofences
  Future<void> refreshGeofences() async {
    await _loadSavedGeofences();
    if (_childLocation != null) {
      _checkAllGeofences();
    }
  }

  // Clear all geofences
  Future<void> clearAllGeofences() async {
    _activeGeofences.clear();
    _geofenceStatuses.clear();
    await StorageService.clearGeofences();
    onGeofencesUpdated?.call(_activeGeofences);
  }

  // Dispose and cleanup
  Future<void> dispose() async {
    _pollTimer?.cancel();
    _cleanupTimer?.cancel();
    _firebaseSubscription?.cancel();
    _positionStream?.cancel();
    _activeGeofences.clear();
    _geofenceStatuses.clear();
  }
}

// Additional enums and classes for the service
enum GeofenceStatus {
  unknown,
  insideOnTime,
  insideOffTime,
  outsideOnTime,
  outsideOffTime,
}

enum GeofenceEvent {
  enter,
  exit,
  dwell,
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
