// 
import 'package:firebase_database/firebase_database.dart';
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
  StreamSubscription<DatabaseEvent>? _firebaseHrSubscription;
  
  // Firebase Database reference
  final DatabaseReference _hrRef = FirebaseDatabase.instance.ref().child('test_write/hrValue');
  // Change 'heartRate' to your actual Firebase path
  
  // Current values
  double _currentHR = 0;
  double _currentHRV = 0;
  double _avgHR = 0;
  double _avgHRV = 0;
  
  // For HRV calculation
  final List<double> _recentHRValues = [];
  final int _hrvCalculationWindow = 10; // Number of HR values to use for HRV calculation
  
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
    _startFirebaseMonitoring();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _firebaseHrSubscription?.cancel();
    super.dispose();
  }

  void _startFirebaseMonitoring() {
    // Listen to Firebase Realtime Database for HR values
    _firebaseHrSubscription = _hrRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null) {
        double hrValue;
        
        // Handle different data types from Firebase
        if (data is num) {
          hrValue = data.toDouble();
        } else if (data is Map) {
          // If your Firebase structure is more complex, extract HR value
          // Example: {'value': 75, 'timestamp': 1234567890}
          hrValue = (data['value'] as num?)?.toDouble() ?? 0;
        } else {
          print('Unexpected data type from Firebase: ${data.runtimeType}');
          return;
        }
        
        if (hrValue > 0) {
          _processNewHRValue(hrValue);
        }
      }
    }, onError: (error) {
      print('Firebase listening error: $error');
    });
  }

  void _processNewHRValue(double hrValue) {
    final now = DateTime.now();
    
    setState(() {
      _currentHR = hrValue;
      
      // Add to recent HR values for HRV calculation
      _recentHRValues.add(hrValue);
      if (_recentHRValues.length > _hrvCalculationWindow) {
        _recentHRValues.removeAt(0);
      }
      
      // Calculate HRV from recent HR values
      _currentHRV = _calculateHRV(_recentHRValues);
      
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
      
      // Update status and check for alerts
      _updateStatus();
      _checkForAlerts();
    });
  }

  double _calculateHRV(List<double> hrValues) {
    if (hrValues.length < 2) return 0;
    
    // Method 1: RMSSD (Root Mean Square of Successive Differences)
    // This is a common time-domain HRV measure
    
    // First, convert HR (beats per minute) to RR intervals (milliseconds)
    List<double> rrIntervals = hrValues.map((hr) => 60000 / hr).toList();
    
    // Calculate successive differences
    List<double> successiveDiffs = [];
    for (int i = 1; i < rrIntervals.length; i++) {
      successiveDiffs.add(rrIntervals[i] - rrIntervals[i - 1]);
    }
    
    if (successiveDiffs.isEmpty) return 0;
    
    // Calculate RMSSD
    double sumSquaredDiffs = successiveDiffs.map((diff) => diff * diff).reduce((a, b) => a + b);
    double rmssd = sqrt(sumSquaredDiffs / successiveDiffs.length);
    
    return rmssd;
  }

  // Alternative HRV calculation methods you can use:
  
  double _calculateHRVStandardDeviation(List<double> hrValues) {
    // Method 2: Standard Deviation of RR intervals (SDNN)
    if (hrValues.length < 2) return 0;
    
    List<double> rrIntervals = hrValues.map((hr) => 60000 / hr).toList();
    double mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    double variance = rrIntervals.map((rr) => pow(rr - mean, 2)).reduce((a, b) => a + b) / rrIntervals.length;
    return sqrt(variance);
  }

  double _calculateHRVPNN50(List<double> hrValues) {
    // Method 3: pNN50 - percentage of successive RR intervals that differ by more than 50ms
    if (hrValues.length < 2) return 0;
    
    List<double> rrIntervals = hrValues.map((hr) => 60000 / hr).toList();
    int count = 0;
    
    for (int i = 1; i < rrIntervals.length; i++) {
      if ((rrIntervals[i] - rrIntervals[i - 1]).abs() > 50) {
        count++;
      }
    }
    
    return (count / (rrIntervals.length - 1)) * 100;
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

  // Method to manually fetch HR data (if needed for initial load)
  Future<void> _fetchInitialHRData() async {
    try {
      // Fetch last N heart rate values for initial HRV calculation
      final snapshot = await _hrRef.limitToLast(_hrvCalculationWindow).get();
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          data.forEach((key, value) {
            if (value is num) {
              _recentHRValues.add(value.toDouble());
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching initial HR data: $e');
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
                  maxX: spots.length > 0 ? spots.length.toDouble() - 1 : 0,
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
      // appBar: AppBar(
      //   title: const Text('Health Monitor'),
      //   backgroundColor: Colors.blue[700],
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.settings),
      //       onPressed: () => _showSettingsDialog(),
      //     ),
      //   ],
      // ),
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