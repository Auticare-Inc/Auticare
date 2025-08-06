import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class MiniMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String locationName;
  final bool isInSafeZone;

  const MiniMapWidget({
    Key? key,
    this.latitude,
    this.longitude,
    required this.locationName,
    this.isInSafeZone = true,
  }) : super(key: key);

  @override
  _MiniMapWidgetState createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<MiniMapWidget> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Marker> _markers = {};
  
  // Default location (you can replace with actual current location)
  late gmaps.LatLng _currentLocation;

  @override
  void initState() {
    super.initState();
    // Set default location or use provided coordinates
    _currentLocation = gmaps.LatLng(
      widget.latitude ?? 5.6037, // Default to Accra, Ghana
      widget.longitude ?? -0.1870,
    );
    _createMarker();
  }

  void _createMarker() {
    _markers.add(
      gmaps.Marker(
        markerId: const gmaps.MarkerId('current_location'),
        position: _currentLocation,
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed
        ),
        infoWindow: gmaps.InfoWindow(
          title: 'Current Location',
          snippet: widget.locationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Google Map
            gmaps.GoogleMap(
              onMapCreated: (gmaps.GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: gmaps.CameraPosition(
                target: _currentLocation,
                zoom: 16.0,
              ),
              markers: _markers,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              buildingsEnabled: true,
              trafficEnabled: false,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Custom marker widget for modern design (alternative approach)
class ModernLocationMarker extends StatelessWidget {
  final bool isInSafeZone;
  final double size;

  const ModernLocationMarker({
    Key? key,
    this.isInSafeZone = true,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isInSafeZone ? Colors.green : Colors.red).withOpacity(0.2),
            ),
          ),
          // Middle circle
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isInSafeZone ? Colors.green : Colors.red).withOpacity(0.4),
            ),
          ),
          // Inner dot
          Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInSafeZone ? Colors.green : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: size * 0.15,
            ),
          ),
        ],
      ),
    );
  }
}