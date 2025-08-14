
import 'package:autismapp/screens/placesPage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utilities/placesPageUtils/appColors.dart';
import 'geoCard.dart';
import 'geoModels.dart';
import 'geoService.dart';

class GeofenceManagementPage extends StatefulWidget {
  @override
  _GeofenceManagementPageState createState() => _GeofenceManagementPageState();
}

class _GeofenceManagementPageState extends State<GeofenceManagementPage> {
  final EnhancedGeofencingService _geofencingService = EnhancedGeofencingService();
  List<Geofence> _geofences = [];

  @override
  void initState() {
    super.initState();
    _loadGeofences();
  }

  void _loadGeofences() {
    setState(() {
      _geofences = _geofencingService.activeGeofences;
    });
  }

  Future<void> _deleteGeofence(String geofenceId) async {
    await _geofencingService.removeGeofence(geofenceId);
    _loadGeofences();
  }

  Future<void> _toggleGeofence(Geofence geofence) async {
    // This would require updating the geofence service to support toggling
    // For now, you can implement this by removing and re-adding with different status
    _loadGeofences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header section with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F4FD),

                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_searching,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Geofences',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_geofences.length} ${_geofences.length == 1 ? 'zone' : 'zones'} configured',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Content area
            Expanded(
              child: _geofences.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        _loadGeofences();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: _geofences.length,
                        itemBuilder: (context, index) {
                          final geofence = _geofences[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: GeofenceCard(
                              geofence: geofence,
                              onDelete: () => _deleteGeofence(geofence.id),
                              onToggle: () => _toggleGeofence(geofence),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'No Active Geofences',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Create safe zones to monitor your child\'s location and receive alerts when they enter or leave designated areas.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ()=> context.goNamed('placesSearchPage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.add_location_alt, size: 20),
                label: Text(
                  'Create Your First Geofence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Start with common places like home, school, or playground for effective monitoring.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}