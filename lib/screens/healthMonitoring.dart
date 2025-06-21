// pubspec.yaml dependencies needed:
// fl_chart: ^0.65.0
// intl: ^0.19.0

// pubspec.yaml dependencies needed:
// fl_chart: ^0.68.0
// intl: ^0.19.0

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';

class HRHRVMonitorPage extends StatefulWidget {
  const HRHRVMonitorPage({super.key});

  @override
  State<HRHRVMonitorPage> createState() => _HRHRVMonitorPageState();
}

class _HRHRVMonitorPageState extends State<HRHRVMonitorPage> {
  Timer? _dataTimer;
  final List<HeartRateData> _hrData = [];
  final List<HRVData> _hrvData = [];
  
  // Current values
  double _currentHR = 0;
  double _currentHRV = 0;
  double _avgHR = 0;
  double _avgHRV = 0;
  
  // Status indicators
  String _hrStatus = 'Normal';
  String _hrvStatus = 'Normal';
  Color _hrStatusColor = Colors.green;
  Color _hrvStatusColor = Colors.green;
  
  // Alert system
  bool _isAlertActive = false;
  String _alertMessage = '';
  
  // Settings for autism-friendly monitoring
  bool _enableSoundAlerts = false;
  bool _enableVibrationAlerts = true;
  final int _monitoringDuration = 60; // minutes
  
  // Baseline values (should be set based on individual's normal ranges)
  final double _baselineHRMin = 60;
  final double _baselineHRMax = 100;
  final double _baselineHRVMin = 20;
  final double _baselineHRVMax = 50;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _dataTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _generateMockData();
      _updateStatus();
      _checkForAlerts();
    });
  }

  void _generateMockData() {
    // Simulate real sensor data with realistic variations
    final now = DateTime.now();
    final random = Random();
    
    // Generate realistic HR data (60-120 bpm with variations)
    double baseHR = 75 + (random.nextDouble() - 0.5) * 20;
    if (_isStressEvent()) {
      baseHR += 15 + random.nextDouble() * 15; // Stress response
    }
    
    // Generate realistic HRV data (inversely related to stress)
    double baseHRV = 35 + (random.nextDouble() - 0.5) * 15;
    if (baseHR > 90) {
      baseHRV -= 10; // Lower HRV during higher HR
    }
    
    setState(() {
      _currentHR = baseHR.clamp(50, 150);
      _currentHRV = baseHRV.clamp(10, 60);
      
      // Add to data lists
      _hrData.add(HeartRateData(now, _currentHR));
      _hrvData.add(HRVData(now, _currentHRV));
      
      // Keep only last 100 data points for performance
      if (_hrData.length > 100) {
        _hrData.removeAt(0);
      }
      if (_hrvData.length > 100) {
        _hrvData.removeAt(0);
      }
      
      // Calculate averages
      _calculateAverages();
    });
  }

  bool _isStressEvent() {
    // Simulate occasional stress events (10% chance)
    return Random().nextDouble() < 0.1;
  }

  void _calculateAverages() {
    if (_hrData.isNotEmpty) {
      _avgHR = _hrData.map((e) => e.value).reduce((a, b) => a + b) / _hrData.length;
    }
    if (_hrvData.isNotEmpty) {
      _avgHRV = _hrvData.map((e) => e.value).reduce((a, b) => a + b) / _hrvData.length;
    }
  }

  void _updateStatus() {
    // Update HR status
    if (_currentHR < _baselineHRMin) {
      _hrStatus = 'Low';
      _hrStatusColor = Colors.blue;
    } else if (_currentHR > _baselineHRMax) {
      _hrStatus = 'Elevated';
      _hrStatusColor = Colors.orange;
    } else {
      _hrStatus = 'Normal';
      _hrStatusColor = Colors.green;
    }

    // Update HRV status
    if (_currentHRV < _baselineHRVMin) {
      _hrvStatus = 'Low (Stress)';
      _hrvStatusColor = Colors.red;
    } else if (_currentHRV > _baselineHRVMax) {
      _hrvStatus = 'High (Relaxed)';
      _hrvStatusColor = Colors.green;
    } else {
      _hrvStatus = 'Normal';
      _hrvStatusColor = Colors.green;
    }
  }

  void _checkForAlerts() {
    bool shouldAlert = false;
    String alertMsg = '';

    // Check for concerning patterns
    if (_currentHR > 120) {
      shouldAlert = true;
      alertMsg = 'High heart rate detected (${_currentHR.toInt()} bpm)';
    } else if (_currentHRV < 15) {
      shouldAlert = true;
      alertMsg = 'Very low HRV - possible stress response';
    } else if (_currentHR > _baselineHRMax + 20) {
      shouldAlert = true;
      alertMsg = 'Significant HR elevation detected';
    }

    if (shouldAlert && !_isAlertActive) {
      setState(() {
        _isAlertActive = true;
        _alertMessage = alertMsg;
      });
      _triggerAlert();
    } else if (!shouldAlert && _isAlertActive) {
      setState(() {
        _isAlertActive = false;
        _alertMessage = '';
      });
    }
  }

  void _triggerAlert() {
    // Here you would integrate with actual notification systems
    // For now, we'll just show a visual alert
    if (_enableVibrationAlerts) {
      // Trigger haptic feedback
      // HapticFeedback.mediumImpact();
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required IconData icon,
    String? subtitle,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart({
    required String title,
    required List<FlSpot> spots,
    required Color lineColor,
    required double minY,
    required double maxY,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  minX: 0,
                  maxX: spots.length.toDouble() - 1,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prepare chart data
    final hrSpots = _hrData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final hrvSpots = _hrvData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Health Monitor'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert banner
            if (_isAlertActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _alertMessage,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Current metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Heart Rate',
                    value: _currentHR.toInt().toString(),
                    unit: 'bpm',
                    status: _hrStatus,
                    statusColor: _hrStatusColor,
                    icon: Icons.favorite,
                    subtitle: 'Avg: ${_avgHR.toInt()} bpm',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'HRV',
                    value: _currentHRV.toInt().toString(),
                    unit: 'ms',
                    status: _hrvStatus,
                    statusColor: _hrvStatusColor,
                    icon: Icons.timeline,
                    subtitle: 'Avg: ${_avgHRV.toInt()} ms',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Charts
            _buildChart(
              title: 'Heart Rate Trend',
              spots: hrSpots,
              lineColor: Colors.red,
              minY: 50,
              maxY: 150,
            ),

            const SizedBox(height: 16),

            _buildChart(
              title: 'HRV Trend',
              spots: hrvSpots,
              lineColor: Colors.blue,
              minY: 0,
              maxY: 80,
            ),

            const SizedBox(height: 24),

            // Status summary
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoring Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Session: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.data_usage, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Data points: ${_hrData.length}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _isAlertActive ? Icons.warning : Icons.check_circle,
                          size: 16,
                          color: _isAlertActive ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAlertActive ? 'Alert Active' : 'All Normal',
                          style: TextStyle(
                            color: _isAlertActive ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monitor Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Sound Alerts'),
              value: _enableSoundAlerts,
              onChanged: (value) => setState(() => _enableSoundAlerts = value),
            ),
            SwitchListTile(
              title: const Text('Vibration Alerts'),
              value: _enableVibrationAlerts,
              onChanged: (value) => setState(() => _enableVibrationAlerts = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class HeartRateData {
  final DateTime timestamp;
  final double value;

  HeartRateData(this.timestamp, this.value);
}

class HRVData {
  final DateTime timestamp;
  final double value;

  HRVData(this.timestamp, this.value);
}