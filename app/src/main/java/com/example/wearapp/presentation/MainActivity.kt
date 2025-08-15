//
//package com.example.wearapp.presentation
//
//import android.app.ActivityManager
//import android.app.AppOpsManager
//import android.content.BroadcastReceiver
//import android.content.Context
//import android.content.Intent
//import android.content.IntentFilter
//import android.content.pm.PackageManager
//import android.net.Uri
//import android.os.Build
//import android.os.Bundle
//import android.os.Process
//import android.util.Log
//import androidx.activity.ComponentActivity
//import androidx.activity.compose.setContent
//import androidx.activity.result.contract.ActivityResultContracts
//import androidx.compose.foundation.background
//import androidx.compose.foundation.layout.Arrangement
//import androidx.compose.foundation.layout.Column
//import androidx.compose.foundation.layout.fillMaxSize
//import androidx.compose.foundation.layout.fillMaxWidth
//import androidx.compose.runtime.Composable
//import androidx.compose.runtime.getValue
//import androidx.compose.runtime.mutableStateOf
//import androidx.compose.runtime.remember
//import androidx.compose.runtime.setValue
//import androidx.compose.ui.tooling.preview.Devices
//import androidx.core.content.ContextCompat
//import androidx.wear.compose.material.MaterialTheme
//import androidx.wear.compose.material.Text
//import com.example.wearapp.presentation.theme.WearAppTheme
//import kotlinx.coroutines.CoroutineScope
//import kotlinx.coroutines.Dispatchers
//import kotlinx.coroutines.delay
//import kotlinx.coroutines.guava.await
//import kotlinx.coroutines.launch
//import androidx.health.services.client.HealthServices
//import androidx.health.services.client.data.DataType
//import androidx.health.services.client.data.PassiveListenerConfig
//import androidx.lifecycle.lifecycleScope
//import androidx.localbroadcastmanager.content.LocalBroadcastManager
//import com.google.firebase.database.FirebaseDatabase
//
//class MainActivity : ComponentActivity() {
//    private val TAG = "MainActivity"
//
//    // State tracking
//    private var monitoringSetupComplete = false
//    private var lastHeartRateReceived = 0L
//    private var heartRateCount = 0
//    private var serviceStartAttempts = 0
//
//    // Latest optional values that can arrive alongside HR
//    private var lastSteps: Long? = null
//    private var lastDistance: Double? = null
//    private var lastCalories: Double? = null
//
//    /** Single-permission launcher for BACKGROUND sensors (SDK 34+) */
//    private val backgroundSensorsLauncher =
//        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
//            if (granted) {
//                Log.d(TAG, "✅ BODY_SENSORS_BACKGROUND granted")
//                logAppOpsForSensors()
//                if (hasSensorsPermissions()) setupPassiveHealthMonitoring()
//            } else {
//                Log.e(TAG, "❌ BODY_SENSORS_BACKGROUND denied")
//                promptOpenAppSettings()
//            }
//        }
//
//    /** Batch launcher (WITHOUT BACKGROUND) */
//    private val permissionLauncher = registerForActivityResult(
//        ActivityResultContracts.RequestMultiplePermissions()
//    ) { permissions ->
//        Log.d(TAG, "Permission results received: $permissions")
//
//        val hasBodySensors = permissions[android.Manifest.permission.BODY_SENSORS] == true
//
//        if (hasBodySensors) {
//            if (hasSensorsPermissions()) {
//                Log.d(TAG, "✅ Foreground + background sensors already granted")
//                logAppOpsForSensors()
//                setupPassiveHealthMonitoring()
//            } else {
//                Log.d(TAG, "BODY_SENSORS granted but BACKGROUND missing → requesting BACKGROUND")
//                ensureBackgroundSensorsPermission()
//            }
//        } else {
//            Log.e(TAG, "❌ BODY_SENSORS denied. Cannot start monitoring.")
//        }
//
//        // Debug logging
//        permissions.forEach { (permission, granted) ->
//            if (!granted) Log.e(TAG, "Denied permission: $permission")
//        }
//    }
//
//    /** Check both foreground + background sensors (background required only on SDK 34+) */
//    private fun hasSensorsPermissions(): Boolean {
//        val hasSensors = ContextCompat.checkSelfPermission(
//            this, android.Manifest.permission.BODY_SENSORS
//        ) == PackageManager.PERMISSION_GRANTED
//
//        val needsBg = Build.VERSION.SDK_INT >= 34
//        val hasBackground = !needsBg || ContextCompat.checkSelfPermission(
//            this, android.Manifest.permission.BODY_SENSORS_BACKGROUND
//        ) == PackageManager.PERMISSION_GRANTED
//
//        return hasSensors && hasBackground
//    }
//
//    /** Request BACKGROUND sensors alone when missing (SDK 34+) */
//    private fun ensureBackgroundSensorsPermission() {
//        if (Build.VERSION.SDK_INT < 34) return
//        val perm = android.Manifest.permission.BODY_SENSORS_BACKGROUND
//        val granted = ContextCompat.checkSelfPermission(this, perm) == PackageManager.PERMISSION_GRANTED
//        if (!granted) {
//            backgroundSensorsLauncher.launch(perm)
//        }
//    }
//
//    /** Settings fallback for "Don't ask again" */
//    private fun promptOpenAppSettings() {
//        val intent = Intent(
//            android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
//            Uri.fromParts("package", packageName, null)
//        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
//        startActivity(intent)
//        Log.w(TAG, "Ask user: Settings → Apps → $packageName → Permissions → Sensors → Allow")
//    }
//
//    // AppOps logger (works across API levels)
//    private fun logAppOpsForSensors() {
//        try {
//            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
//
//            fun modeName(mode: Int) = when (mode) {
//                AppOpsManager.MODE_ALLOWED -> "MODE_ALLOWED"
//                AppOpsManager.MODE_ERRORED -> "MODE_ERRORED"
//                AppOpsManager.MODE_IGNORED -> "MODE_IGNORED"
//                AppOpsManager.MODE_DEFAULT -> "MODE_DEFAULT"
//                AppOpsManager.MODE_FOREGROUND -> "MODE_FOREGROUND"
//                else -> "MODE_$mode"
//            }
//
//            val opFg = AppOpsManager.permissionToOp(android.Manifest.permission.BODY_SENSORS)
//            val modeFg = if (opFg != null)
//                appOps.unsafeCheckOpNoThrow(opFg, Process.myUid(), packageName)
//            else AppOpsManager.MODE_DEFAULT
//
//            val modeBg = if (Build.VERSION.SDK_INT >= 34) {
//                val opBg = AppOpsManager.permissionToOp(android.Manifest.permission.BODY_SENSORS_BACKGROUND)
//                if (opBg != null) appOps.unsafeCheckOpNoThrow(opBg, Process.myUid(), packageName)
//                else AppOpsManager.MODE_DEFAULT
//            } else {
//                AppOpsManager.MODE_ALLOWED
//            }
//
//            Log.i(TAG, "AppOps BODY_SENSORS=${modeName(modeFg)}, BODY_SENSORS_BACKGROUND=${modeName(modeBg)}")
//        } catch (e: Throwable) {
//            Log.w(TAG, "AppOps check failed", e)
//        }
//    }
//
//    // Broadcast receiver
//    private val healthDataReceiver = object : BroadcastReceiver() {
//        override fun onReceive(context: Context?, intent: Intent?){
//            Log.d(TAG, "Broadcast received: ${intent?.action}")
//
//            when (intent?.action) {
//                MyPassiveListenerService.ACTION_HEART_RATE_DATA -> {
//                    val heartRate = intent.getDoubleExtra(MyPassiveListenerService.EXTRA_HEART_RATE, 0.0)
//                    val timestamp = intent.getLongExtra(MyPassiveListenerService.EXTRA_TIMESTAMP, 0L)
//
//                    // Capture optional extras if present (from PassiveListenerService)
//                    lastSteps = if (intent.hasExtra(MyPassiveListenerService.EXTRA_STEPS))
//                        intent.getLongExtra(MyPassiveListenerService.EXTRA_STEPS, 0L) else null
//
//                    lastDistance = if (intent.hasExtra(MyPassiveListenerService.EXTRA_DISTANCE))
//                        intent.getDoubleExtra(MyPassiveListenerService.EXTRA_DISTANCE, 0.0) else null
//
//                    lastCalories = if (intent.hasExtra(MyPassiveListenerService.EXTRA_CALORIES))
//                        intent.getDoubleExtra(MyPassiveListenerService.EXTRA_CALORIES, 0.0) else null
//
//                    heartRateCount++
//                    val now = System.currentTimeMillis()
//                    val sinceLast = if (lastHeartRateReceived > 0) now - lastHeartRateReceived else -1
//                    lastHeartRateReceived = now
//
//                    Log.d(TAG, " HR #$heartRateCount: $heartRate BPM at $timestamp")
//                    Log.d(TAG, " Time since last reading: ${sinceLast}ms")
//                    Log.d(TAG, " Extras → steps=$lastSteps, distanceMeters=$lastDistance, caloriesKcal=$lastCalories")
//
//                    sendHeartRateToFirebase(heartRate, timestamp)
//                }
//                MyPassiveListenerService.ACTION_LOCATION_DATA -> {
//                    val latitude = intent.getDoubleExtra(MyPassiveListenerService.EXTRA_LATITUDE, 0.0)
//                    val longitude = intent.getDoubleExtra(MyPassiveListenerService.EXTRA_LONGITUDE, 0.0)
//                    val timestamp = intent.getLongExtra(MyPassiveListenerService.EXTRA_TIMESTAMP, 0L)
//                    Log.d(TAG, " Location: $latitude, $longitude at $timestamp")
//                    sendLocationToFirebase(latitude, longitude, timestamp)
//                }
//            }
//        }
//    }
//
//    // Lifecycle
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//
//        setContent { WearApp() }
//
//        registerHealthDataReceiver()
//        checkAndRequestPermissions()
//        startPeriodicHealthCheck()
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        try {
//            LocalBroadcastManager.getInstance(this).unregisterReceiver(healthDataReceiver)
//            Log.d(TAG, "Broadcast receiver unregistered")
//        } catch (e: Exception) {
//            Log.e(TAG, "Error unregistering receiver", e)
//        }
//        Log.d(TAG, " MainActivity destroyed but leaving service running")
//    }
//
//    override fun onResume() {
//        super.onResume()
//        Log.d(TAG, " MainActivity resumed")
//        logAppOpsForSensors()
//        checkServiceStatus()
//
//        if (monitoringSetupComplete) {
//            val timeSinceLastReading = if (lastHeartRateReceived > 0) {
//                (System.currentTimeMillis() - lastHeartRateReceived) / 1000
//            } else -1
//            Log.d(TAG, " Monitoring - Setup: $monitoringSetupComplete, Readings: $heartRateCount, Last: ${timeSinceLastReading}s ago")
//        }
//    }
//
//    private fun registerHealthDataReceiver() {
//        val filter = IntentFilter().apply {
//            addAction(MyPassiveListenerService.ACTION_HEART_RATE_DATA)
//            addAction(MyPassiveListenerService.ACTION_LOCATION_DATA)
//        }
//        LocalBroadcastManager.getInstance(this).registerReceiver(healthDataReceiver, filter)
//        Log.d(TAG, "Health data broadcast receiver registered")
//    }
//
//    // Permissions entry point
//    private fun checkAndRequestPermissions() {
//        Log.d(TAG, "=== CHECKING PERMISSIONS ===")
//
//        val batchPermissions = arrayOf(
//            android.Manifest.permission.BODY_SENSORS,
//            android.Manifest.permission.ACCESS_FINE_LOCATION,
//            android.Manifest.permission.ACCESS_COARSE_LOCATION,
//            android.Manifest.permission.ACTIVITY_RECOGNITION,
//            android.Manifest.permission.POST_NOTIFICATIONS
//        )
//
//        (batchPermissions + android.Manifest.permission.BODY_SENSORS_BACKGROUND).forEach { permission ->
//            val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
//            Log.d(TAG, "Permission $permission: ${if (granted) "GRANTED" else "DENIED"}")
//        }
//
//        val missingBatch = batchPermissions.filter {
//            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
//        }
//
//        if (missingBatch.isEmpty()) {
//            Log.d(TAG, "✅ Batch permissions already granted")
//            if (hasSensorsPermissions()) {
//                logAppOpsForSensors()
//                setupPassiveHealthMonitoring()
//            } else {
//                ensureBackgroundSensorsPermission()
//            }
//        } else {
//            Log.d(TAG, "❌ Requesting batch permissions: $missingBatch")
//            permissionLauncher.launch(batchPermissions)
//        }
//    }
//
//    // Health Services setup
//    private fun setupPassiveHealthMonitoring() {
//        Log.d(TAG, "=== SETTING UP PASSIVE HEALTH MONITORING ===")
//
//        if (!hasSensorsPermissions()) {
//            Log.w(TAG, "Sensors permissions missing; requesting BACKGROUND…")
//            ensureBackgroundSensorsPermission()
//            return
//        }
//
//        val healthServiceManager = HealthServiceManager(this)
//
//        lifecycleScope.launch {
//            try {
//                Log.d(TAG, "Starting health monitoring using HealthServiceManager...")
//                val success = healthServiceManager.startHealthMonitoring()
//
//                if (success) {
//                    monitoringSetupComplete = true
//                    Log.d(TAG, " SUCCESS! Health monitoring started via HealthServiceManager!")
//                    Log.d(TAG, "MyPassiveListenerService should now receive heart rate data")
//                    delay(3000)
//                    checkServiceStatus()
//                } else {
//                    Log.e(TAG, "❌ Failed to start monitoring via HealthServiceManager")
//                    Log.d(TAG, " Trying fallback registration method...")
//                    setupPassiveHealthMonitoringFallback()
//                }
//            } catch (e: Exception) {
//                Log.e(TAG, "❌ Exception in health monitoring setup", e)
//            }
//        }
//    }
//
//    private fun setupPassiveHealthMonitoringFallback() {
//        Log.d(TAG, "=== FALLBACK SETUP METHOD ===")
//        serviceStartAttempts++
//
//        CoroutineScope(Dispatchers.IO).launch {
//            try {
//                val healthClient = HealthServices.getClient(this@MainActivity)
//                val passiveMonitoringClient = healthClient.passiveMonitoringClient
//
//                Log.d(TAG, "Health client created successfully (fallback attempt #$serviceStartAttempts)")
//
//                val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
//                val supportedDataTypes = capabilities.supportedDataTypesPassiveMonitoring
//                Log.d(TAG, "Supported passive data types: ${supportedDataTypes.map { it.name }}")
//
//                if (!supportedDataTypes.contains(DataType.HEART_RATE_BPM)) {
//                    Log.e(TAG, "❌ HR monitoring not supported on this device")
//                    return@launch
//                }
//
//                val config = PassiveListenerConfig.builder()
//                    .setDataTypes(setOf(DataType.HEART_RATE_BPM))
//                    .setShouldUserActivityInfoBeRequested(false)
//                    .build()
//
//                Log.d(TAG, "Registering PassiveListenerService for heart rate only...")
//                passiveMonitoringClient.setPassiveListenerServiceAsync(
//                    MyPassiveListenerService::class.java,
//                    config
//                ).await()
//
//                monitoringSetupComplete = true
//                Log.d(TAG, "🎉 SUCCESS! Fallback registration completed!")
//            } catch (e: Exception) {
//                Log.e(TAG, "❌ Fallback setup failed", e)
//            }
//        }
//    }
//
//    private suspend fun checkHealthServicesStatus() {
//        try {
//            val healthClient = HealthServices.getClient(this@MainActivity)
//            val passiveMonitoringClient = healthClient.passiveMonitoringClient
//            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
//            Log.d(TAG, "✅ Health Services responsive; supported types: ${capabilities.supportedDataTypesPassiveMonitoring.size}")
//        } catch (e: Exception) {
//            Log.e(TAG, "❌ Health Services may not be working properly", e)
//        }
//    }
//
//    private fun checkServiceStatus() {
//        try {
//            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
//            val services = activityManager.getRunningServices(Integer.MAX_VALUE)
//
//            var foundService = false
//            services.forEach { serviceInfo ->
//                val serviceName = serviceInfo.service.className
//                Log.d(TAG, "🔍 Running service: $serviceName")
//
//                if (serviceName.contains("MyPassiveListenerService")) {
//                    foundService = true
//                    Log.d(TAG, "✅ Found MyPassiveListenerService running!")
//                    Log.d(TAG, " PID: ${serviceInfo.pid}, started: ${serviceInfo.activeSince}, fg: ${serviceInfo.foreground}")
//                }
//                if (serviceName.contains("healthservices", ignoreCase = true)) {
//                    Log.d(TAG, " Health Services found: $serviceName")
//                }
//            }
//
//            if (!foundService && monitoringSetupComplete) {
//                Log.w(TAG, "⚠️ MyPassiveListenerService should be running but isn't detected (may be managed by Health Services)")
//            }
//        } catch (e: Exception) {
//            Log.e(TAG, "Error checking service status", e)
//        }
//    }
//
//    private fun startPeriodicHealthCheck() {
//        lifecycleScope.launch {
//            while (true) {
//                delay(60_000)
//                if (monitoringSetupComplete) {
//                    val secs = if (lastHeartRateReceived > 0) {
//                        (System.currentTimeMillis() - lastHeartRateReceived) / 1000
//                    } else -1L
//
//                    Log.d(TAG, " Health Check - Readings: $heartRateCount, Last: ${secs}s ago")
//
//                    if (secs > 600 && secs != -1L) {
//                        Log.w(TAG, "⚠️ No HR readings for >10 minutes. Tips:")
//                        Log.w(TAG, "   - Ensure the watch is snug")
//                        Log.w(TAG, "   - Move/exercise briefly")
//                        Log.w(TAG, "   - Clean the sensor")
//                        Log.w(TAG, "   - Reboot the watch if needed")
//                    }
//
//                    if (heartRateCount == 0) {
//                        checkServiceStatus()
//                    }
//                }
//            }
//        }
//    }
//
//    private fun sendHeartRateToFirebase(heartRate: Double, timestamp: Long) {
//        Log.d(TAG, "Attempting to send HR to Firebase: $heartRate")
//        try {
//            val database = FirebaseDatabase.getInstance()
//            val ref = database.getReference("test_write_health")
//
//            // Add optional steps/distance/calories if present
//            val data = buildMap<String, Any> {
//                put("timestamp", timestamp)
//                put("heartRate", heartRate)
//                put(
//                    "deviceId",
//                    android.provider.Settings.Secure.getString(
//                        applicationContext.contentResolver,
//                        android.provider.Settings.Secure.ANDROID_ID
//                    )
//                )
//                put("readingNumber", heartRateCount)
//
//                lastSteps?.let { put("steps", it) }
//                lastDistance?.let { put("distanceMeters", it) }
//                lastCalories?.let { put("caloriesKcal", it) }
//            }
//
//            ref.push().setValue(data)
//                .addOnSuccessListener { Log.d(TAG, "✅ HR data sent to Firebase: $data") }
//                .addOnFailureListener { e -> Log.e(TAG, "❌ Failed to send HR data", e) }
//        } catch (e: Exception) {
//            Log.e(TAG, "Error sending heart rate", e)
//        }
//    }
//
//    private fun sendLocationToFirebase(latitude: Double, longitude: Double, timestamp: Long) {
//        Log.d(TAG, "Attempting to send location to Firebase: $latitude, $longitude")
//        try {
//            val database = FirebaseDatabase.getInstance()
//            val ref = database.getReference("test_write_location")
//            val data = mapOf(
//                "timestamp" to timestamp,
//                "latitude" to latitude,
//                "longitude" to longitude,
//                "deviceId" to android.provider.Settings.Secure.getString(
//                    applicationContext.contentResolver,
//                    android.provider.Settings.Secure.ANDROID_ID
//                )
//            )
//            ref.push().setValue(data)
//                .addOnSuccessListener { Log.d(TAG, "✅ Location data sent to Firebase") }
//                .addOnFailureListener { e -> Log.e(TAG, "❌ Failed to send location data", e) }
//        } catch (e: Exception) {
//            Log.e(TAG, "Error sending location", e)
//        }
//    }
//}
//
//// ---------------------------
//// UI (unchanged)
//// ---------------------------
//@Composable
//fun WearApp() {
//    var monitoringStatus by remember { mutableStateOf("Initializing health monitoring...") }
//
//    WearAppTheme {
//        Column(
//            modifier = androidx.compose.ui.Modifier
//                .fillMaxSize()
//                .background(MaterialTheme.colors.background),
//            verticalArrangement = Arrangement.Center
//        ) {
//            Text(
//                modifier = androidx.compose.ui.Modifier.fillMaxWidth(),
//                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
//                color = MaterialTheme.colors.primary,
//                text = "Health Monitor"
//            )
//            Text(
//                modifier = androidx.compose.ui.Modifier.fillMaxWidth(),
//                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
//                color = MaterialTheme.colors.secondary,
//                text = monitoringStatus
//            )
//        }
//    }
//}
//
//@androidx.compose.ui.tooling.preview.Preview(
//    device = Devices.WEAR_OS_SMALL_ROUND,
//    showSystemUi = true
//)
//@Composable
//fun DefaultPreview() {
//    WearApp()
//}

package com.example.wearapp.presentation

import android.content.BroadcastReceiver
import android.content.Intent
import android.util.Log
import androidx.activity.ComponentActivity
import android.content.Context

// ... (all your imports unchanged)

class MainActivity : ComponentActivity() {
    private val TAG = "MainActivity"

    // State tracking
    private var monitoringSetupComplete = false
    private var lastHeartRateReceived = 0L
    private var heartRateCount = 0
    private var serviceStartAttempts = 0

    // Latest optional values that can arrive alongside HR
    private var lastSteps: Long? = null
    private var lastDistance: Double? = null
    private var lastCalories: Double? = null

    // launchers / helpers unchanged...

    // Broadcast receiver
    private val healthDataReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: android.content.Context?, intent: Intent?) {
            Log.d(TAG, "Broadcast received: ${intent?.action}")

            when (intent?.action) {
                MyPassiveListenerService.ACTION_HEART_RATE_DATA -> {
                    val heartRate = intent.getDoubleExtra(MyPassiveListenerService.EXTRA_HEART_RATE, 0.0)
                    val timestamp = intent.getLongExtra(MyPassiveListenerService.EXTRA_TIMESTAMP, 0L)

                    // Capture optional extras if present (from PassiveListenerService)
                    lastSteps = if (intent.hasExtra(MyPassiveListenerService.EXTRA_STEPS))
                        intent.getLongExtra(MyPassiveListenerService.EXTRA_STEPS, 0L) else null

                    lastDistance = if (intent.hasExtra(MyPassiveListenerService.EXTRA_DISTANCE))
                        intent.getDoubleExtra(MyPassiveListenerService.EXTRA_DISTANCE, 0.0) else null

                    lastCalories = if (intent.hasExtra(MyPassiveListenerService.EXTRA_CALORIES))
                        intent.getDoubleExtra(MyPassiveListenerService.EXTRA_CALORIES, 0.0) else null

                    heartRateCount++
                    val now = System.currentTimeMillis()
                    val sinceLast = if (lastHeartRateReceived > 0) now - lastHeartRateReceived else -1
                    lastHeartRateReceived = now

                    Log.d(TAG, " HR #$heartRateCount: $heartRate BPM at $timestamp")
                    Log.d(TAG, " Time since last reading: ${sinceLast}ms")
                    Log.d(TAG, " Extras → steps=$lastSteps, distanceMeters=$lastDistance, caloriesKcal=$lastCalories")

                    // ⛔️ No DB write here anymore — PassiveListenerService already sent it
                    // sendHeartRateToFirebase(heartRate, timestamp)
                }
            }
        }
    }

    // Lifecycle, permissions, setup, health checks — all unchanged ..
}
