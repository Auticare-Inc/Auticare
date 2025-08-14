import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../repositories/childStateRepo.dart';
import 'GeofenceUtils.dart/geoManagementPage.dart';
import 'healthMonitoring.dart';
import 'mapScreen.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({Key? key}) : super(key: key);

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // Live values from Firebase
  int _selectedIndex = 0;
  double heartRate = 0.0;
  int currentSteps = 0;
  double caloriesBurned = 0.0; // caloriesKcal
  double distanceMeters = 0.0;

  Map<String, Map<String, dynamic>> _deviceReadings = {};
  DateTime? _latestHeartRateTime;
  DateTime? _latestStepsTime;
  DateTime? _latestCaloriesTime;
  DateTime? _latestDistanceTime;
  String? _latestDeviceId;
  double _lastNonZeroSteps = 0.0;
  double _lastNonZeroCalories = 0.0;
  double _lastNonZeroDistance = 0.0;
  double _accumulatedSteps = 0.0;
  double _accumulatedCalories = 0.0;
  double _accumulatedDistance = 0.0;
  Timer? _dailyResetTimer;
  DateTime? _lastResetDate;
  Map<String, int> _lastStepCounts = {}; // Track last step count per device
 int _dailyStepTotal = 0; // Our calculated daily total
 Map<String, double> _lastCalorieCounts = {};
 Map<String, double> _lastDistanceCounts = {};


  // Optional targets (static; adjust to your app's logic)
  int targetSteps = 5000;
  double caloriesTarget = 1000.0;

  // Timestamp for "Updated:" label
  DateTime? lastUpdated;

  // Firebase - Updated approach for better real-time updates
  final DatabaseReference _healthRef =
      FirebaseDatabase.instance.ref().child('test_write_health');
  StreamSubscription<DatabaseEvent>? _sub;
  StreamSubscription<DatabaseEvent>? _childAddedSub;
  StreamSubscription<DatabaseEvent>? _childChangedSub;
  StreamSubscription<DatabaseEvent>? _connSub;
  bool _isConnected = false;

  // Connection status timer
  Timer? _connectionTimer;

  // Tiny HR trend (enhanced like HRV monitoring page)
  final List<FlSpot> _hrSpots = [];
  int _hrIndex = 0;

  // ENHANCED: Track last processed readings to avoid duplicates (like HRV page)
  int _lastProcessedReading = -1;
  final Map<String, int> _lastProcessedReadings = {};

  // ENHANCED: Current device tracking (like HRV page)
  String _currentDeviceId = '';
  int _currentReadingNumber = 0;

  // Sleep demo values (unchanged)
  Duration deepSleep = const Duration(hours: 1, minutes: 45);
  Duration lightSleep = const Duration(hours: 5, minutes: 10);
  Duration timeAwake = const Duration(minutes: 23);
  Duration totalSleep = const Duration(hours: 7, minutes: 58);

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _startConnectionTimer();
    _checkAndResetIfNewDay();
    _startDailyResetTimer();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _childAddedSub?.cancel();
    _childChangedSub?.cancel();
    _connSub?.cancel();
    _connectionTimer?.cancel();
    _dailyResetTimer?.cancel(); //
    super.dispose();
  }

  void _startConnectionTimer() {
    // Timer to check connection status - using same logic as HRV page
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (lastUpdated != null) {
        final timeSinceLastUpdate =
            DateTime.now().difference(lastUpdated!).inSeconds;
        final newConnectionStatus =
            timeSinceLastUpdate < 30; // Same 30-second threshold as HRV page

        if (_isConnected != newConnectionStatus) {
          setState(() {
            _isConnected = newConnectionStatus;
          });
        }
      }
    });
  }

  // ENHANCED: Improved Firebase initialization (like HRV monitoring page)
  Future<void> _initializeFirebase() async {

    try {
      // 1. Start real-time listeners first (like HRV page)
      _startFirebaseListeners();

      // 2. Get initial data immediately
      final snapshot = await _healthRef.once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value;
      }

      // 3. Monitor connection status
      _startConnectionMonitoring();
    } catch (error) {
      print('HealthPage: Firebase initialization error: $error');
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _startFirebaseListeners() {
    // ENHANCED: Use the same listener pattern as HRV monitoring page
    // Listen for child changes (device data updates) - PRIMARY LISTENER
    _childChangedSub = _healthRef.onChildChanged.listen(
      (DatabaseEvent event) {
        _processFirebaseSnapshot(event.snapshot);
      },
      onError: (error) {
        setState(() {
          _isConnected = false;
        });
      },
    );

    // Listen for child additions (new devices)
    _childAddedSub = _healthRef.onChildAdded.listen(
      (DatabaseEvent event) {
        _processFirebaseSnapshot(event.snapshot);
      },
      onError: (error) {
      },
    );

    // REMOVED: Backup listener to avoid duplicate processing
  }

  void _startConnectionMonitoring() {
    // Monitor Firebase connection state (same as HRV page)
    _connSub = FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (!connected) {
        setState(() {
          _isConnected = false;
        });
      }
    });
  }

  // ENHANCED: Process Firebase snapshot (same logic as HRV page)
  void _processFirebaseSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value;
    if (data != null && data is Map) {
      final deviceData = data as Map<dynamic, dynamic>;
      final deviceKey = snapshot.key ?? 'unknown';


      // ENHANCED: Process heart rate with same duplicate checking as HRV page
      final heartRateRaw = deviceData['heartRate'];
      final deviceId = deviceData['deviceId']?.toString() ?? deviceKey;
      final readingNumber = deviceData['readingNumber'] ?? 0;

      if (heartRateRaw is num && heartRateRaw > 0) {
        // ENHANCED: Check for duplicate readings (like HRV page)
        if (readingNumber <= _lastProcessedReading && readingNumber > 0) {
          return;
        }

        final now = DateTime.now();

        setState(() {
          // Update heart rate with timestamp tracking
          heartRate = heartRateRaw.toDouble();
          _latestHeartRateTime = now;
          _currentDeviceId = deviceId;
          _currentReadingNumber = readingNumber;
          lastUpdated = now;
          _isConnected = true;

          // ENHANCED: Update last processed reading
          if (readingNumber > 0) {
            _lastProcessedReading = readingNumber;
          }

          // ENHANCED: Add to HR trend chart (with better indexing)
          _hrSpots.add(FlSpot((_hrIndex++).toDouble(), heartRate));
          if (_hrSpots.length > 30) {
            _hrSpots.removeAt(0);
            // Adjust indices when removing old data
            for (int i = 0; i < _hrSpots.length; i++) {
              _hrSpots[i] = FlSpot(i.toDouble(), _hrSpots[i].y);
            }
            _hrIndex = _hrSpots.length;
          }
        });
      }

      // Continue processing other metrics (steps, calories, distance)
      _processDeviceDataForOtherMetrics(deviceData, deviceKey);
    }
  }

  void _processDeviceDataForOtherMetrics(
    Map<dynamic, dynamic> deviceData, String key) {
  final stepsRaw = deviceData['steps'];
  final caloriesRaw = deviceData['caloriesKcal'];
  final distanceRaw = deviceData['distanceMeters'];
  final deviceId = deviceData['deviceId']?.toString() ?? key;
  final readingNumber = deviceData['readingNumber'] ?? 0;
  final timestampRaw = deviceData['timestamp'];

  DateTime readingTime;
  if (timestampRaw is num) {
    readingTime = DateTime.fromMillisecondsSinceEpoch(timestampRaw.toInt());
  } else {
    readingTime = DateTime.now();
  }

  bool uiUpdated = false;

  setState(() {
    // FIXED: Steps - Calculate incremental difference
    if (stepsRaw is num) {
      if (_latestStepsTime == null ||
          readingTime.isAfter(_latestStepsTime!) ||
          readingTime.isAtSameMomentAs(_latestStepsTime!)) {
        
        int rawSteps = stepsRaw.toInt().abs();
        
        // Handle scaling for very small values
        if (rawSteps == 0 && stepsRaw is double && stepsRaw.abs() > 0.000001) {
          rawSteps = (stepsRaw * 1000000).round().abs();
        }

        if (rawSteps > 0) {
          // Get the last step count for this device
          int lastStepCount = _lastStepCounts[deviceId] ?? 0;
          
          if (lastStepCount == 0) {
            // First reading from this device - don't add to total yet
            _lastStepCounts[deviceId] = rawSteps;
          } else {
            // Calculate the difference since last reading
            int stepDifference = rawSteps - lastStepCount;
            
            // Only add if it's a reasonable increment (prevent huge jumps)
            if (stepDifference > 0 && stepDifference < 1000) {
              _dailyStepTotal += stepDifference;
              _lastStepCounts[deviceId] = rawSteps;
            } else if (stepDifference < 0) {
              // Device reset or new day - treat as new baseline
              _lastStepCounts[deviceId] = rawSteps;
            } else if (stepDifference >= 1000) {
            }
          }
          
          currentSteps = _dailyStepTotal;
          _latestStepsTime = readingTime;
          uiUpdated = true;
        }
      }
    }

    
    // FIXED CALORIES - Now using incremental logic like steps
    if (caloriesRaw is num) {
      if (_latestCaloriesTime == null ||
          readingTime.isAfter(_latestCaloriesTime!) ||
          readingTime.isAtSameMomentAs(_latestCaloriesTime!)) {
        
        double rawCalories = caloriesRaw.toDouble().abs();
        
        if (rawCalories < 0.000001 && caloriesRaw.abs() > 0) {
          rawCalories = (caloriesRaw.abs() * 1000000);
        }

        if (rawCalories > 0) {
          // NEW: Track last calories per device (similar to steps)
          double lastCalorieCount = _lastCalorieCounts[deviceId] ?? 0.0;
          
          if (lastCalorieCount == 0.0) {
            // First reading from this device - set baseline
            _lastCalorieCounts[deviceId] = rawCalories;
          } else {
            // Calculate the difference since last reading
            double calorieDifference = rawCalories - lastCalorieCount;
            
            // Only add if it's a reasonable increment
            if (calorieDifference > 0 && calorieDifference < 500) { // Reasonable max per reading
              _accumulatedCalories += calorieDifference;
              _lastCalorieCounts[deviceId] = rawCalories;
            } else if (calorieDifference < 0) {
              // Device reset - new baseline
              _lastCalorieCounts[deviceId] = rawCalories;
            } else if (calorieDifference >= 500) {
              // Huge jump - ignore
            }
          }
          
          caloriesBurned = _accumulatedCalories;
          _latestCaloriesTime = readingTime;
          uiUpdated = true;
        }
      }
    }


    if (distanceRaw is num) {
      if (_latestDistanceTime == null ||
          readingTime.isAfter(_latestDistanceTime!) ||
          readingTime.isAtSameMomentAs(_latestDistanceTime!)) {
        
        double rawDistance = distanceRaw.toDouble().abs();
        
        if (rawDistance < 0.000001 && distanceRaw.abs() > 0) {
          rawDistance = (distanceRaw.abs() * 1000000);
        }

        if (rawDistance > 0) {
          // NEW: Track last distance per device (similar to steps)
          double lastDistanceCount = _lastDistanceCounts[deviceId] ?? 0.0;
          
          if (lastDistanceCount == 0.0) {
            // First reading from this device - set baseline
            _lastDistanceCounts[deviceId] = rawDistance;
          } else {
            // Calculate the difference since last reading
            double distanceDifference = rawDistance - lastDistanceCount;
            
            // Only add if it's a reasonable increment
            if (distanceDifference > 0 && distanceDifference < 1000) { // Reasonable max per reading (1km)
              _accumulatedDistance += distanceDifference;
              _lastDistanceCounts[deviceId] = rawDistance;
            } else if (distanceDifference < 0) {
              // Device reset - new baseline
              _lastDistanceCounts[deviceId] = rawDistance;
            } else if (distanceDifference >= 1000) {
              // Huge jump - ignore
            }
          }
          
          distanceMeters = _accumulatedDistance;
          _latestDistanceTime = readingTime;
          uiUpdated = true;
        }
      }
    }


    // Update connection status
    if (uiUpdated) {
      if (lastUpdated == null || readingTime.isAfter(lastUpdated!)) {
        lastUpdated = readingTime;
        _isConnected = true;
        _latestDeviceId = deviceId;
      }

      if (readingNumber > 0) {
        _lastProcessedReadings[deviceId] = readingNumber;
      }
    }
  });
}

void _resetDailyTotals() {

  final int checkpointReading = _currentReadingNumber;
  final DateTime? checkpointTime = lastUpdated;

  setState(() {
    // 1) Clear displayed/accumulated totals
    _accumulatedSteps = 0.0;
    _accumulatedCalories = 0.0;
    _accumulatedDistance = 0.0;
    _dailyStepTotal = 0;

    currentSteps = 0;
    caloriesBurned = 0.0;
    distanceMeters = 0.0;

    if (checkpointReading > 0) {
      _lastProcessedReading = checkpointReading;                // used by HR
      if (_currentDeviceId.isNotEmpty) {
        _lastProcessedReadings[_currentDeviceId] = checkpointReading; // per-device
      }
    }

    if (checkpointTime != null) {
      // Push all metric cursors forward so only NEWER data is accepted
      _latestHeartRateTime = checkpointTime;
      _latestStepsTime = checkpointTime;
      _latestCaloriesTime = checkpointTime;
      _latestDistanceTime = checkpointTime;
      lastUpdated = checkpointTime; // keep header in sync
    }

    _deviceReadings.forEach((deviceId, reading) {
      final stepsVal = reading['steps'];
      if (stepsVal is num && stepsVal > 0) {
        int raw = stepsVal.toInt().abs();
        if (raw == 0 && stepsVal is double && stepsVal.abs() > 0.000001) {
          raw = (stepsVal * 1000000).round().abs();
        }
        _lastStepCounts[deviceId] = raw;
      }

      final calVal = reading['caloriesKcal'];
      if (calVal is num && calVal > 0) {
        double raw = calVal.toDouble().abs();
        if (raw < 0.000001 && calVal.abs() > 0) {
          raw = (calVal.abs() * 1000000);
        }
        _lastCalorieCounts[deviceId] = raw;
      }

      final distVal = reading['distanceMeters'];
      if (distVal is num && distVal > 0) {
        double raw = distVal.toDouble().abs();
        if (raw < 0.000001 && distVal.abs() > 0) {
          raw = (distVal.abs() * 1000000);
        }
        _lastDistanceCounts[deviceId] = raw;
      }
    });

    _lastResetDate = DateTime.now();
  });

}


  void _checkAndResetIfNewDay() {
    final now = DateTime.now();

    // If no previous reset date or it's a new day
    if (_lastResetDate == null ||
        now.day != _lastResetDate!.day ||
        now.month != _lastResetDate!.month ||
        now.year != _lastResetDate!.year) {
      _resetDailyTotals();
    }
  }

  void _startDailyResetTimer() {
    _dailyResetTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndResetIfNewDay();
    });
  }

  // ENHANCED: Better refresh method (like HRV page)
  Future<void> _refreshData() async {

    // Cancel existing listeners
    await _sub?.cancel();
    await _childAddedSub?.cancel();
    await _childChangedSub?.cancel();

    // Reset tracking (like HRV page)
    _lastProcessedReadings.clear();
    _lastProcessedReading = -1;

    // Reinitialize
    await _initializeFirebase();
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return buildHomePage();
      case 1:
        return GeofencingMapsPage();
      case 2:
        return HRHRVMonitorPage();
      case 3:
        return GeofenceManagementPage();
      default:
        return buildHomePage();
    }
  }

  // ------- UI -------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            HapticFeedback.lightImpact();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHomePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + connection pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                Row(
                  children: [
                    _connPill(_isConnected),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          size: 22, color: Colors.black54),
                      onPressed: _refreshData,
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore,
                          size: 22, color: Colors.black54),
                      onPressed: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Daily Totals'),
                            content: const Text(
                                'Are you sure you want to reset today\'s steps, calories, and distance?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _resetDailyTotals();
                                  Navigator.pop(context);
                                },
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // ENHANCED: Enhanced debug info row (like HRV page)
            if (lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last updated: ${_fmtTime(lastUpdated!)} | Device: ${_currentDeviceId.isNotEmpty ? _currentDeviceId : (_latestDeviceId ?? "Unknown")}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      'Reading #${_currentReadingNumber} | Devices: ${_deviceReadings.length} | Connection: ${_isConnected ? "✓" : "✗"}',
                      style: TextStyle(
                          fontSize: 10,
                          color: _isConnected ? Colors.green : Colors.red),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Heart Rate
            _buildHeartRateCard(),

            const SizedBox(height: 20),

            // Steps + Calories
            Row(
              children: [
                Expanded(child: _buildStepsCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildCaloriesCard()),
              ],
            ),

            const SizedBox(height: 20),

            // Distance
            _buildDistanceCard(),

            const SizedBox(height: 20),

            // Bedtime
            _buildBedtimeCard(),

            const SizedBox(height: 20),

            // Emergency SMS + Geofencing
            Row(
              children: [
                Expanded(child: _buildEmergencySMSTab()),
                const SizedBox(width: 16),
                Expanded(child: _buildGeofencingTab()),
              ],
            ),

            const SizedBox(height: 20),

            _buildPersonalDataSection(),
          ],
        ),
      ),
    );
  }

  Widget _connPill(bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ok ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.wifi : Icons.wifi_off,
              size: 14, color: ok ? Colors.green : Colors.red),
          const SizedBox(width: 6),
          Text(ok ? 'Connected' : 'Disconnected',
              style: TextStyle(
                  fontSize: 12, color: ok ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    final hasTrend = _hrSpots.length >= 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBadge(Icons.favorite, Colors.red),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Heart Rate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Child\'s current BPM',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                heartRate > 0 ? heartRate.toStringAsFixed(0) : '--',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? Colors.black : Colors.grey,
                ),
              ),
              const Text(' bpm', style: TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 20),
          // ENHANCED: Better chart with improved data handling
          SizedBox(
            height: 72,
            child: hasTrend
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      clipData: FlClipData.all(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _hrSpots,
                          isCurved: true,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          color: Colors.blue,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                      // ENHANCED: Dynamic Y-axis based on data
                      minY: _hrSpots.isNotEmpty
                          ? _hrSpots
                                  .map((spot) => spot.y)
                                  .reduce((a, b) => a < b ? a : b) -
                              10
                          : 0,
                      maxY: _hrSpots.isNotEmpty
                          ? _hrSpots
                                  .map((spot) => spot.y)
                                  .reduce((a, b) => a > b ? a : b) +
                              10
                          : 100,
                    ),
                  )
                : Center(
                    child: Text(
                      'Waiting for data…',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    final progress = targetSteps == 0 ? 0.0 : currentSteps / targetSteps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.directions_walk, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Text('Steps taken today',
              style: TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (targetSteps == 0 ? 1 : targetSteps).toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: List.generate(8, (i) {
                  final v = (currentSteps * (0.7 + i * 0.05)).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        color: Colors.blue.withOpacity(0.85),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv('Current', '$currentSteps'),
              _kv('Target', '$targetSteps'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    final progress = caloriesTarget == 0
        ? 0.0
        : (caloriesBurned / caloriesTarget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: const [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Calories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Text('Calories burned',
              style: TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  Text(
                    caloriesBurned > 0
                        ? caloriesBurned.toStringAsFixed(1)
                        : '--',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv(
                  'Calories',
                  caloriesBurned > 0
                      ? '${caloriesBurned.toStringAsFixed(1)} kcal'
                      : '-- kcal'),
              _kv('Target', '${caloriesTarget.toStringAsFixed(0)} kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard() {
    final String distanceText = distanceMeters.abs() >= 1000
        ? '${(distanceMeters.abs() / 1000).toStringAsFixed(2)} km'
        : distanceMeters != 0
            ? '${distanceMeters.abs().toStringAsFixed(2)} m'
            : '-- m';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Row(
        children: [
          _iconBadge(Icons.route, Colors.green, radius: 12),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Distance',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              Text('Total distance covered',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const Spacer(),
          Text(
            distanceText,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isConnected && distanceMeters != 0
                    ? Colors.black
                    : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBedtimeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBadge(Icons.person, Colors.purple),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Child status',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  // Text('Child is in calm state',
                  //     style: TextStyle(fontSize: 12, color: Colors.black54)),
                  FutureBuilder<Map<String, dynamic>>(
                    future: ChildStateRepo.fetchLatestPrediction(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: Text('---',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54)));
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        final label = snapshot.data!['Label'];
                        final timestamp = snapshot.data!['timestamp'];

                        return Text('Child in ${label} state',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54));
                      } else {
                        return const Center(child: Text('--.'));
                      }
                    },
                  )
                ],
              ),
              const Spacer(),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: Colors.blue, borderRadius: BorderRadius.circular(6)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _sleepStat('Calm', deepSleep, Colors.blue),
              const SizedBox(width: 20),
              _sleepStat('Amused', lightSleep, Colors.green),
              const SizedBox(width: 20),
              _sleepStat('Anxious', timeAwake, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySMSTab() {
    return GestureDetector(
      onTap: () => context.goNamed('emergencyPage'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.emergency, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Emergency SMS',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
            ),
            Text(
              'Quick emergency contacts',
              style:
                  TextStyle(fontSize: 10, color: Colors.red.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofencingTab() {
    return GestureDetector(
      onTap: () => context.goNamed('placesSearchPage'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Geofencing',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green),
            ),
            Text(
              'Location boundaries',
              style:
                  TextStyle(fontSize: 10, color: Colors.green.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Personal Data',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          Row(
            children: [
              GestureDetector(
                  onTap: () => context.goNamed('manageCaregiversPage'),
                  child: Text('see more',
                      style: TextStyle(color: Colors.black54))),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
            ],
          ),
        ],
      ),
    );
  }

  // ------- Small UI helpers -------
  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _iconBadge(IconData icon, Color color, {double radius = 8}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          Text(v,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _sleepStat(String label, Duration d, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _fmtTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

