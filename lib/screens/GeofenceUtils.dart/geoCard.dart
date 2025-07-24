import 'package:flutter/material.dart';

import '../utilities/placesPageUtils/appColors.dart';
import 'geoModels.dart';


class GeofenceCard extends StatelessWidget {
  final Geofence geofence;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  const GeofenceCard({
    Key? key,
    required this.geofence,
    this.onDelete,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: geofence.isActive ? AppColors.primary : Colors.grey,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    geofence.placeName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            SizedBox(height: 12),
            _buildTimeInfo(context),
            SizedBox(height: 12),
            _buildExpiryInfo(),
            SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final isExpired = geofence.isExpired;
    final color = isExpired ? Colors.red : (geofence.isActive ? Colors.green : Colors.grey);
    final text = isExpired ? 'Expired' : (geofence.isActive ? 'Active' : 'Inactive');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
        SizedBox(width: 4),
        Text(
          'Active: ${geofence.startTime.format(context)} - ${geofence.endTime.format(context)}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryInfo() {
    final timeLeft = geofence.expiresAt.difference(DateTime.now());
    final hoursLeft = timeLeft.inHours;
    
    return Row(
      children: [
        Icon(Icons.timer, size: 16, color: AppColors.textSecondary),
        SizedBox(width: 4),
        Text(
          hoursLeft > 0 ? 'Expires in ${hoursLeft}h' : 'Expired',
          style: TextStyle(
            color: hoursLeft > 0 ? AppColors.textSecondary : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!geofence.isExpired) ...[
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(
              geofence.isActive ? Icons.pause : Icons.play_arrow,
              size: 16,
            ),
            label: Text(geofence.isActive ? 'Pause' : 'Resume'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
          SizedBox(width: 8),
        ],
        TextButton.icon(
          onPressed: onDelete,
          icon: Icon(Icons.delete, size: 16),
          label: Text('Delete'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }
}
