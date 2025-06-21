import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  String _locationStatus = 'Getting location...';
  late BitmapDescriptor customIcon;

  bool iconLoaded = false;

  Future<void>loadCustomIcon()async{
    customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30,30)),
       'images/placeholder2.jpg');

    setState(() {
      iconLoaded = true;
    });
  }
  
  // Map styling
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(5.6037, -0.1870), // Accra, Ghana default
    zoom: 18,
  );

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  Future<void> requestPermissions()async{
    if(await Permission.notification.isDenied){
      await Permission.notification.request();
    }
  }



  @override
  void initState() {
    super.initState();
    requestPermissions();
    _initializeLocation();
    loadCustomIcon();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check and request location permissions
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _locationStatus = 'Location permission denied';
          _isLoading = false;
        });
        return;
      }

      // Get initial position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = 'Location found';
        _isLoading = false;
      });

      // Update map camera to current location
      if (_mapController != null) {
        _updateMapLocation(position);
      }

      // Start real-time location tracking
      _startLocationTracking();
    } catch (e) {
      setState(() {
        _locationStatus = 'Error getting location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Show dialog to open app settings
      _showPermissionDialog();
      return false;
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to show your position on the map. Please enable location permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
        });
        _updateMapLocation(position);
      },
      onError: (error) {
        setState(() {
          _locationStatus = 'Error tracking location: $error';
        });
      },
    );
  }

  void _updateMapLocation(Position position) {
    final LatLng newPosition = LatLng(position.latitude, position.longitude);
    
    // Update markers
    setState(() {
      if(iconLoaded){
        _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: newPosition,
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, '
                    'Lng: ${position.longitude.toStringAsFixed(6)}',
          ),
          icon: customIcon
        ),
      };
      }

      // Add accuracy circle
      _circles = {
        Circle(
          circleId: const CircleId('accuracy_circle'),
          center: newPosition,
          radius: position.accuracy,
          fillColor: Colors.blue.withOpacity(0.1),
          strokeColor: Colors.blue.withOpacity(0.3),
          strokeWidth: 1,
        ),
      };
    });

    // Animate camera to new position
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // If we already have a position, update the map
    if (_currentPosition != null) {
      _updateMapLocation(_currentPosition!);
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeLocation,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            circles: _circles,
            myLocationEnabled: false, // We're handling this manually
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            mapType: MapType.hybrid,
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting your location...'),
                  ],
                ),
              ),
            ),
          
          // Location info card
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
                          color: _currentPosition != null ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationStatus,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _currentPosition != null ? Colors.green : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentPosition != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                      Text(
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      Text(
                        'Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Floating action button to center on location
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnCurrentLocation,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
