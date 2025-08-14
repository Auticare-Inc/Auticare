
import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../repositories/cloudFunction.dart';

class HRHRVMonitorPage extends StatefulWidget {
  const HRHRVMonitorPage({super.key});

  @override
  State<HRHRVMonitorPage> createState() => _HRHRVMonitorPageState();
}

class _HRHRVMonitorPageState extends State<HRHRVMonitorPage>
    with AutomaticKeepAliveClientMixin {
  // ---- Runtime state (UI only) ----
  Timer? _dataTimer;
  double _currentHR = 0;
  double _currentHRV = 0;
  double _avgHR = 0;
  double _avgHRV = 0;
  String _currentDeviceId = '';
  int _currentReadingNumber = 0;
  bool _isConnected = false;
  DateTime? _lastUpdate;
  final ScrollController _hrScroll = ScrollController();
  final ScrollController _hrvScroll = ScrollController();
  // --- HRV alert gating ---
 DateTime? _lastHRVPushAt;
 final Duration _hrvPushCooldown = const Duration(minutes: 2);
 bool _wasVeryLowHRV = false; // last cycle status flag

 static final Map<String, int> _lastProcessedReadingsPerDevice = {};

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

  List<double> _hourlyAverages(
  List<HeartRateData> data, {
  DateTime? day,
  int samplesPerHour = 20,
}) {
  final targetDay = day ?? (data.isNotEmpty ? data.last.timestamp : DateTime.now());
  final buckets = List<List<double>>.generate(24, (_) => <double>[]);

  for (final d in data) {
    if (_isSameDay(d.timestamp, targetDay)) {
      buckets[d.timestamp.hour].add(d.value);
    }
  }

  final averages = List<double>.filled(24, 0);
  for (int h = 0; h < 24; h++) {
    final list = buckets[h];
    if (list.isEmpty) continue;
    final start = (list.length - samplesPerHour).clamp(0, list.length);
    final slice  = list.sublist(start);
    final sum    = slice.fold<double>(0, (a, b) => a + b);
    averages[h]  = sum / slice.length;
  }
  return averages;
}

// NEW: listen to both child-added and child-changed like dashboard
static StreamSubscription<DatabaseEvent>? _childAddedSub;
static StreamSubscription<DatabaseEvent>? _childChangedSub;

final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const init = InitializationSettings(android: androidInit, iOS: iosInit);
  await _local.initialize(init);

  // Android 13+ runtime permission
  await _local
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

  // Status indicators
  String _hrStatus = 'Normal';
  String _hrvStatus = 'Normal';
  Color _hrStatusColor = Colors.green;
  Color _hrvStatusColor = Colors.green;

  // HRV calc
  final List<double> _recentHRValues = [];
  final int _hrvCalculationWindow = 10;

  // Settings
  bool _enableSoundAlerts = false;
  bool _enableVibrationAlerts = true;

  // Baselines
  final double _baselineHRMin = 60;
  final double _baselineHRMax = 100;

  // ---- Persistence (survives navigation) ----
  // FIX: Make data + session + subscription static so stream keeps running even if page is popped.
  static final DatabaseReference _healthRef =
      FirebaseDatabase.instance.ref().child('test_write_health');

  static StreamSubscription<DatabaseEvent>? _firebaseSubscription;

  static final List<HeartRateData> _persistentHRData = <HeartRateData>[];
  static final List<HRVData> _persistentHRVData = <HRVData>[];

  static DateTime? _persistentSessionStartTime;
  static int _lastProcessedReading = -1;

  // local mirrors used for rendering (point to the static lists)
  List<HeartRateData> get _hrData => _persistentHRData;
  List<HRVData> get _hrvData => _persistentHRVData;
  DateTime? get _sessionStartTime => _persistentSessionStartTime;

  @override
  void initState() {
    super.initState();
    // FIX: ensure persistent session timestamp
      _initLocalNotifications();
    _persistentSessionStartTime ??= DateTime.now();

    _startOrReuseFirebaseMonitoring();
    _startConnectionTimer();

    // if returning to page, recalc averages and current values
    if (_hrData.isNotEmpty) {
      _currentHR = _hrData.last.value;
      _currentHRV = _hrvData.isNotEmpty ? _hrvData.last.value : 0;
      _lastUpdate = _hrData.last.timestamp;
      _calculateAverages();
      _updateStatus();
      _isConnected = true;
    }
  }

  @override
  void dispose() {
    // FIX: DO NOT cancel Firebase subscription here so background collection continues.
    _dataTimer?.cancel();
    super.dispose();
    _hrScroll.dispose();
    _hrvScroll.dispose();
  }

  // Keep state in tab views
  @override
  bool get wantKeepAlive => true;

  void _startConnectionTimer() {
    _dataTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_lastUpdate == null) return;
      final secs = DateTime.now().difference(_lastUpdate!).inSeconds;
      setState(() => _isConnected = secs < 30);
    });
  }



  void _startOrReuseFirebaseMonitoring() {
  if (_childAddedSub != null || _childChangedSub != null) {
    // already running
    return;
  }

  // PRIMARY: updates to existing device nodes
  _childChangedSub = _healthRef.onChildChanged.listen(
    (DatabaseEvent event) => _processFirebaseSnapshot(event.snapshot),
    onError: (_) => mounted ? setState(() => _isConnected = false) : null,
  );

  // NEW devices under /test_write_health
  _childAddedSub = _healthRef.onChildAdded.listen(
    (DatabaseEvent event) => _processFirebaseSnapshot(event.snapshot),
    onError: (_) => mounted ? setState(() => _isConnected = false) : null,
  );

  // Connection state (same as dashboard; do NOT force false if we have fresh data)
  FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
    final connected = event.snapshot.value as bool? ?? false;
    if (!mounted) return;
    // Use .info/connected as a hint; the 30s timer remains the source of truth
    if (!connected) setState(() => _isConnected = false);
  });

  // Initial fill so charts aren’t empty
  _healthRef.once().then((DatabaseEvent snapshot) {
    final data = snapshot.snapshot.value;
    if (data is Map) {
      data.forEach((_, value) {
        if (value is Map) _processDeviceMap(value);
      });
    }
  });
}


  void _processFirebaseSnapshot(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is Map) {
      _processDeviceMap(value);
    }
  }



  void _processDeviceMap(Map<dynamic, dynamic> deviceData) {
  // same keys as dashboard
  final heartRateRaw = deviceData['heartRate'];
  final deviceId = deviceData['deviceId']?.toString() ?? 'unknown';
  final int readingNumber = (deviceData['readingNumber'] ?? 0) as int;

  // prefer server timestamp if present (ms epoch)
  DateTime timestamp;
  final ts = deviceData['timestamp'];
  if (ts is int && ts > 0) {
    timestamp = DateTime.fromMillisecondsSinceEpoch(ts);
  } else if (ts is num && ts > 0) {
    timestamp = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
  } else {
    timestamp = DateTime.now();
  }

  if (heartRateRaw is num && heartRateRaw > 0) {
    // de-dup exactly like dashboard
    final lastForDevice = _lastProcessedReadingsPerDevice[deviceId] ?? -1;
    if (readingNumber > 0 && readingNumber <= lastForDevice) {
      // stale/duplicate
      return;
    }

    _processNewHRValue(
      heartRateRaw.toDouble(),
      deviceId,
      readingNumber,
      timestamp,
    );

    // update duplicate guards and connection heartbeat
    if (readingNumber > 0) {
      _lastProcessedReading = readingNumber; // global mirror
      _lastProcessedReadingsPerDevice[deviceId] = readingNumber;
    }
    if (mounted) {
      setState(() {
        _lastUpdate = timestamp; // used by the 30s connection timer
        _isConnected = true;
        _currentDeviceId = deviceId;
        _currentReadingNumber = readingNumber;
      });
    }
  }
}


  void _processNewHRValue(
    double hrValue,
    String deviceId,
    int readingNumber,
    DateTime timestamp,
  ) {
    // update last processed reading (only if > 0)
    if (readingNumber > 0) _lastProcessedReading = readingNumber;

    // HRV mock calc from current HR (your original realistic mock kept)
    _recentHRValues.add(hrValue);
    if (_recentHRValues.length > _hrvCalculationWindow) {
      _recentHRValues.removeAt(0);
    }
    final hrv = _calculateRealisticMockHRV(hrValue);

    // Append to persistent series
    final hrData = HeartRateData(timestamp, hrValue);
    final hrvData = HRVData(timestamp, hrv);

    _hrData.add(hrData);
    _hrvData.add(hrvData);

    // Trim to keep memory bounded
    if (_hrData.length > 5000) _hrData.removeRange(0, _hrData.length - 5000);
    if (_hrvData.length > 5000) _hrvData.removeRange(0, _hrvData.length - 5000);

    if (mounted) {
      setState(() {
        _currentHR = hrValue;
        _currentHRV = hrv;
        _currentDeviceId = deviceId;
        _currentReadingNumber = readingNumber;
        _lastUpdate = timestamp;
        _isConnected = true;

        _calculateAverages();
        _updateStatus();
      });
    }
    if (mounted) {
  // after setState(...)
  WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSendHRVAlert());
  }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hrScroll.hasClients) {
        _hrScroll.jumpTo(_hrScroll.position.maxScrollExtent);
      }
      if (_hrvScroll.hasClients) {
        _hrvScroll.jumpTo(_hrvScroll.position.maxScrollExtent);
      }
    });
  }


Future<void> _maybeSendHRVAlert() async {
  final bool isVeryLowNow = _currentHRV < 20;
  final DateTime now = DateTime.now();

  final bool enteredVeryLow = isVeryLowNow && !_wasVeryLowHRV;
  final bool cooledDown = _lastHRVPushAt == null ||
      now.difference(_lastHRVPushAt!) > _hrvPushCooldown;

  if (enteredVeryLow && cooledDown) {
    const android = AndroidNotificationDetails(
      'health_channel',
      'Health Alerts',
      channelDescription: 'Notifications for HR/HRV alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Health notification',
      'Child is very stressed (HRV very low)',
      details,
    );

    _lastHRVPushAt = now;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stress alert sent')),
      );
    }
  }

  _wasVeryLowHRV = isVeryLowNow;
}


  double _calculateRealisticMockHRV(double currentHR) {
    final hour = DateTime.now().hour;
    double timeOfDayFactor = (hour >= 22 || hour <= 6)
        ? 1.3
        : (hour >= 14 && hour <= 18)
            ? 0.8
            : 1.0;

    double baseHRV;
    if (currentHR < 50) {
      baseHRV = 65;
    } else if (currentHR < 60) {
      baseHRV = 55;
    } else if (currentHR < 70) {
      baseHRV = 45;
    } else if (currentHR < 80) {
      baseHRV = 35;
    } else if (currentHR < 90) {
      baseHRV = 25;
    } else if (currentHR < 100) {
      baseHRV = 18;
    } else {
      baseHRV = 12;
    }

    final variation = (math.Random().nextDouble() - 0.5) * 0.4 * baseHRV;
    final finalHRV = (baseHRV + variation) * timeOfDayFactor;
    return math.max(8.0, finalHRV);
  }

  void _calculateAverages() {
    if (_hrData.isNotEmpty) {
      _avgHR = _hrData.fold<double>(0, (a, b) => a + b.value) / _hrData.length;
    }
    if (_hrvData.isNotEmpty) {
      _avgHRV =
          _hrvData.fold<double>(0, (a, b) => a + b.value) / _hrvData.length;
    }
  }


  void _updateStatus() {
  // HR status
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

  // HRV status (compute only — no push here)
  if (_currentHRV < 20) {
    _hrvStatus = 'Very Low (High Stress)';
    _hrvStatusColor = Colors.red;
  } else if (_currentHRV < 30) {
    _hrvStatus = 'Low (Stressed)';
    _hrvStatusColor = Colors.orange;
  } else if (_currentHRV < 45) {
    _hrvStatus = 'Normal';
    _hrvStatusColor = Colors.green;
  } else if (_currentHRV < 60) {
    _hrvStatus = 'Good (Relaxed)';
    _hrvStatusColor = Colors.green;
  } else {
    _hrvStatus = 'Excellent (Very Relaxed)';
    _hrvStatusColor = Colors.blue;
  }
}




DateTime _parseEpoch(dynamic ts) {
  if (ts is int)            return DateTime.fromMillisecondsSinceEpoch(ts);
  if (ts is num)            return DateTime.fromMillisecondsSinceEpoch(ts.toInt());
  if (ts is String) {
    final n = num.tryParse(ts);
    if (n != null)          return DateTime.fromMillisecondsSinceEpoch(n.toInt());
  }
  return DateTime.now();
}

  // ------- UI helpers -------

  Widget _buildConnectionStatus() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_currentDeviceId.isNotEmpty)
              Text(
                'Device: ${_currentDeviceId.substring(0, math.min(8, _currentDeviceId.length))}...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (_lastUpdate != null) ...[
              const SizedBox(width: 8),
              Text(
                DateFormat('HH:mm:ss').format(_lastUpdate!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: statusColor, size: 24),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _isConnected ? Colors.black : Colors.grey),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ),
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }

  // Widget _buildSeriesChart({
  //   required String title,
  //   required List<HeartRateData> data,
  //   required Color lineColor,
  //   required double minY,
  //   required double maxY,
  //   required String unit,
  //   required ScrollController controller,
  //   double pointGapPx = 16, // <- spacing per point (tweak this)
  // }) {
  //   final int n = data.length;
  //   final List<FlSpot> spots =
  //       List<FlSpot>.generate(n, (i) => FlSpot(i.toDouble(), data[i].value));

  //   // total width grows with number of points to give each point pixel spacing
  //   // + 80 padding so last point isn't flush against the edge
  //   final double chartContentWidth = math.max(
  //     MediaQuery.of(context).size.width -
  //         32, // minimum to look fine when few points
  //     (n <= 1 ? 2 : (n - 1)) * pointGapPx + 80,
  //   );

  //   return Card(
  //     elevation: 4,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(title,
  //               style:
  //                   const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  //           const SizedBox(height: 16),
  //           SizedBox(
  //             height: 220,
  //             child: spots.isEmpty
  //                 ? Center(
  //                     child: Text('Waiting for data...',
  //                         style:
  //                             TextStyle(color: Colors.grey[600], fontSize: 16)))
  //                 : Scrollbar(
  //                     controller: controller,
  //                     thumbVisibility: true,
  //                     child: SingleChildScrollView(
  //                       controller: controller,
  //                       scrollDirection: Axis.horizontal,
  //                       child: SizedBox(
  //                         width: chartContentWidth,
  //                         child: LineChart(
  //                           LineChartData(
  //                             minX: 0,
  //                             maxX: math.max((n - 1).toDouble(), 5),
  //                             minY: minY,
  //                             maxY: maxY,
  //                             gridData: FlGridData(
  //                               show: true,
  //                               drawVerticalLine: false,
  //                               horizontalInterval: (maxY - minY) / 4,
  //                               getDrawingHorizontalLine: (v) => FlLine(
  //                                   color: Colors.grey.withOpacity(0.25),
  //                                   strokeWidth: 1),
  //                             ),
  //                             titlesData: FlTitlesData(
  //                               leftTitles: AxisTitles(
  //                                 sideTitles: SideTitles(
  //                                   showTitles: true,
  //                                   reservedSize: 40,
  //                                   getTitlesWidget: (value, meta) => Text(
  //                                       value.toInt().toString(),
  //                                       style: const TextStyle(fontSize: 12)),
  //                                 ),
  //                               ),
  //                               bottomTitles: const AxisTitles(
  //                                 sideTitles: SideTitles(
  //                                     showTitles: false), // hide x labels
  //                               ),
  //                               topTitles: const AxisTitles(
  //                                   sideTitles: SideTitles(showTitles: false)),
  //                               rightTitles: const AxisTitles(
  //                                   sideTitles: SideTitles(showTitles: false)),
  //                             ),
  //                             borderData: FlBorderData(
  //                               show: true,
  //                               border: Border.all(
  //                                   color: Colors.grey.withOpacity(0.3)),
  //                             ),
  //                             lineBarsData: [
  //                               LineChartBarData(
  //                                 spots: spots,
  //                                 isCurved: true,
  //                                 color: lineColor,
  //                                 barWidth: 3,
  //                                 isStrokeCapRound: true,
  //                                 dotData: const FlDotData(show: false),
  //                                 belowBarData: BarAreaData(
  //                                     show: true,
  //                                     color: lineColor.withOpacity(0.10)),
  //                               ),
  //                             ],
  //                             lineTouchData: LineTouchData(
  //                               enabled: true,
  //                               touchTooltipData: LineTouchTooltipData(
  //                                 getTooltipColor: (_) =>
  //                                     Colors.blueGrey.withOpacity(0.85),
  //                                 getTooltipItems: (barSpots) =>
  //                                     barSpots.map((s) {
  //                                   final int i =
  //                                       s.spotIndex.clamp(0, data.length - 1);
  //                                   final DateTime ts = data[i].timestamp;
  //                                   final timeStr =
  //                                       DateFormat('HH:mm:ss').format(ts);
  //                                   return LineTooltipItem(
  //                                     'Time: $timeStr\n${s.y.toStringAsFixed(0)} $unit',
  //                                     const TextStyle(
  //                                         color: Colors.white,
  //                                         fontWeight: FontWeight.bold,
  //                                         fontSize: 12),
  //                                   );
  //                                 }).toList(),
  //                               ),
  //                               handleBuiltInTouches: true,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
//   Widget _buildSeriesChart({
//   required String title,
//   required List<HeartRateData> data,
//   required Color lineColor,          // reused as bar color
//   required double minY,
//   required double maxY,
//   required String unit,
//   required ScrollController controller, // unused now but kept for signature compatibility
//   double pointGapPx = 16, // unused for bars
// }) {
//   // Build hourly averages for “today” (or last day in the data)
//   final day = data.isNotEmpty ? data.last.timestamp : DateTime.now();
//   final hourly = _hourlyAverages(data, day: day, samplesPerHour: 20);

//   // Clamp bars to maxY to avoid drawing past the frame
//   final groups = List.generate(24, (h) {
//     final v = hourly[h].clamp(minY, maxY);
//     return BarChartGroupData(
//       x: h,
//       barRods: [
//         BarChartRodData(
//           toY: v,
//           // make it pretty
//           color: lineColor,
//           width: 12,
//           borderRadius: BorderRadius.circular(4),
//           rodStackItems: const [], // keep simple
//         ),
//       ],
//     );
//   });

//   return Card(
//     elevation: 4,
//     clipBehavior: Clip.antiAlias, // ensure nothing overflows rounded corners
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 220,
//             child: BarChart(
//               BarChartData(
//                 minY: minY,
//                 maxY: maxY,
//                 barGroups: groups,
//                 alignment: BarChartAlignment.spaceBetween,
//                 //clipData: FlClipData.all(), // hard clip inside chart too
//                 gridData: FlGridData(
//                   show: true,
//                   drawVerticalLine: false,
//                   horizontalInterval: (maxY - minY) / 4,
//                   getDrawingHorizontalLine: (v) => FlLine(
//                     color: Colors.grey.withOpacity(0.25),
//                     strokeWidth: 1,
//                   ),
//                 ),
//                 borderData: FlBorderData(
//                   show: true,
//                   border: Border.all(color: Colors.grey.withOpacity(0.3)),
//                 ),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 40,
//                       getTitlesWidget: (value, meta) =>
//                           Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) {
//                         final h = value.toInt();
//                         // show labels every 6 hours to cover the whole day
//                         if (h % 6 == 0) {
//                           final label = '${h.toString().padLeft(2, '0')}:00';
//                           return Padding(
//                             padding: const EdgeInsets.only(top: 4),
//                             child: Text(label, style: const TextStyle(fontSize: 10)),
//                           );
//                         }
//                         return const SizedBox.shrink();
//                       },
//                       reservedSize: 28,
//                     ),
//                   ),
//                   topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 barTouchData: BarTouchData(
//                   enabled: true,
//                   touchTooltipData: BarTouchTooltipData(
//                     getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.85),
//                     getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                       final h = group.x.toInt();
//                       final label = '${h.toString().padLeft(2, '0')}:00';
//                       return BarTooltipItem(
//                         '$label\n${rod.toY.toStringAsFixed(0)} $unit',
//                         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

Widget _buildSeriesChart({
  required String title,
  required List<HeartRateData> data,
  required Color lineColor, // used as bar color
  required double minY,
  required double maxY,
  required String unit,
  required ScrollController controller, // kept for signature
  double pointGapPx = 16,
}) {
  final day = data.isNotEmpty ? data.last.timestamp : DateTime.now();
  final hourly = _hourlyAverages(data, day: day, samplesPerHour: 20);

  final groups = List.generate(24, (h) {
    final v = hourly[h].clamp(0, maxY); // bars from 0 up
    return BarChartGroupData(
      x: h,
      barRods: [
        BarChartRodData(
          toY: v.toDouble(),
          color: lineColor,
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  });

  return Card(
    elevation: 4,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: 0,                 // bars should start at zero
                maxY: maxY,
                barGroups: groups,
                alignment: BarChartAlignment.spaceBetween,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.25),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) =>
                          Text(v.toInt().toString(), style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final h = value.toInt();
                        if (h % 6 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${h.toString().padLeft(2, '0')}:00',
                                style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.85),
                    getTooltipItem: (group, _, rod, __) {
                      final h = group.x.toInt();
                      return BarTooltipItem(
                        '${h.toString().padLeft(2, '0')}:00\n${rod.toY.toStringAsFixed(0)} $unit',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
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
    super.build(context);

    final hrvAsHRLike = _hrvData
        .map((e) => HeartRateData(e.timestamp, e.value))
        .toList(growable: false); // reuse same builder for HRV

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        title: const Text('Health Monitor',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE8F4FD),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.blue),
              onPressed: _showSettingsDialog),
          IconButton(
            icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off,
                color: Colors.blue),
            onPressed: () {
              // Manual refresh: do not reset static listener; just reset duplicate filter to accept new reads
              _lastProcessedReading = -1;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monitoring refreshed')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildConnectionStatus(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Heart Rate',
                value: _currentHR > 0 ? _currentHR.toInt().toString() : '--',
                unit: 'bpm',
                status: _hrStatus,
                statusColor: _hrStatusColor,
                icon: Icons.favorite,
                subtitle: _avgHR > 0 ? 'Avg: ${_avgHR.toInt()} bpm' : 'No data',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'HRV',
                value: _currentHRV > 0 ? _currentHRV.toInt().toString() : '--',
                unit: 'ms',
                status: _hrvStatus,
                statusColor: _hrvStatusColor,
                icon: Icons.timeline,
                subtitle:
                    _avgHRV > 0 ? 'Avg: ${_avgHRV.toInt()} ms' : 'No data',
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // FIX: charts that start at x=0, latest at right, no x labels, y labeled, tooltip shows time
          _buildSeriesChart(
            title: 'Heart Rate Trend',
            data: _hrData,
            lineColor: Colors.red,
            minY: 0,
            maxY: 180,
            unit: 'bpm',
            controller: _hrScroll,
            pointGapPx: 18, // a little wider spacing for HR
          ),
          const SizedBox(height: 16),
          _buildSeriesChart(
            title: 'HRV Trend',
            data: _hrvData
                .map((e) => HeartRateData(e.timestamp, e.value))
                .toList(),
            lineColor: Colors.blue,
            minY: 0,
            maxY: 150,
            unit: 'ms',
            controller: _hrvScroll,
            pointGapPx: 16,
          ),

          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monitoring Summary',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Session start: ${DateFormat('HH:mm:ss').format(_sessionStartTime ?? DateTime.now())}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.data_usage, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('Data points: ${_hrData.length}',
                          style: TextStyle(color: Colors.grey[700])),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.sensors, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('Reading #$_currentReadingNumber',
                          style: TextStyle(color: Colors.grey[700])),
                    ]),
                  ]),
            ),
          ),
        ]),
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
              onChanged: (value) =>
                  setState(() => _enableVibrationAlerts = value),
            ),
            const SizedBox(height: 16),
            const Text('Monitoring: test_write_health',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (_currentDeviceId.isNotEmpty)
              Text('Device ID: $_currentDeviceId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Last Reading: $_lastProcessedReading',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          TextButton(
            onPressed: () {
              _lastProcessedReading = -1;
              Navigator.pop(context);
            },
            child: const Text('Refresh'),
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
