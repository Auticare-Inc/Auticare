//
//package com.example.wearapp.presentation
//
//import android.content.Intent
//import android.util.Log
//import androidx.health.services.client.PassiveListenerService
//import androidx.health.services.client.data.DataPoint
//import androidx.health.services.client.data.DataPointContainer
//import androidx.health.services.client.data.DataType
//import androidx.localbroadcastmanager.content.LocalBroadcastManager
//
//class MyPassiveListenerService : PassiveListenerService() {
//
//    private val TAG = "PassiveListenerService"
//
//    companion object {
//        const val ACTION_HEART_RATE_DATA = "com.example.wearapp.HEART_RATE_DATA"
//        const val ACTION_LOCATION_DATA = "com.example.wearapp.LOCATION_DATA"
//        const val EXTRA_HEART_RATE = "heart_rate"
//
//        //const val EXTRA_HEART_RATE_BPM_STATS = "heart_rate_bpm_stats"
//        const val EXTRA_STEPS = "steps"
//        const val EXTRA_DISTANCE = "distance_meters"
//        const val EXTRA_CALORIES = "calories_kcal"
//        const val EXTRA_LATITUDE = "latitude"
//        const val EXTRA_LONGITUDE = "longitude"
//        const val EXTRA_TIMESTAMP = "timestamp"
//    }
//
//    override fun onNewDataPointsReceived(dataPoints: DataPointContainer) {
//        Log.d(TAG, "onNewDataPointsReceived: $dataPoints")
//
//        // --- Heart Rate & Metadata ---
//        runCatching {
//            val hrPoints = dataPoints.getData(DataType.HEART_RATE_BPM)
//            //val hrBSPoints = dataPoints.getData(DataType.HEART_RATE_BPM_STATS)
//            // val steps = dataPoints.getData(DataType.STEPS).lastOrNull()?.value as? Long
//            val distance = dataPoints.getData(DataType.DISTANCE).lastOrNull()?.value as? Double
//            val calories = dataPoints.getData(DataType.CALORIES).lastOrNull()?.value as? Double
//            val steps = dataPoints.getData(DataType.STEPS)
//                .mapNotNull { it.value as? Long }
//                .sum()
////
////            val distance = dataPoints.getData(DataType.DISTANCE)
////                .mapNotNull { it.value as? Double }
////                .sum()
////
////            val calories = dataPoints.getData(DataType.CALORIES)
////                .mapNotNull { it.value as? Double }
////                .sum()
//
//
//            for (point in hrPoints) {
//                val bpm = point.value
//                val timestamp = System.currentTimeMillis()
//                val intent = Intent(ACTION_HEART_RATE_DATA).apply {
//                    putExtra(EXTRA_HEART_RATE, bpm)
//                    //putExtra(EXTRA_HEART_RATE_BPM_STATS, bpm)
//                    steps?.let { putExtra(EXTRA_STEPS, it) }
//                    distance?.let { putExtra(EXTRA_DISTANCE, it) }
//                    calories?.let { putExtra(EXTRA_CALORIES, it) }
//                    putExtra(EXTRA_TIMESTAMP, timestamp)
//                }
//                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
//                Log.d(
//                    TAG,
//                    " HR: $bpm BPM,HRBPM:$bpm BPM, steps=$steps, dist=$distance, kcal=$calories, timestamp=$timestamp"
//                )
//            }
//
//        }.onFailure {
//            Log.e(TAG, "Error processing HR batch", it)
//        }
//
//        // --- Location ---
//        runCatching {
//            val locations = dataPoints.getData(DataType.LOCATION)
//            for (point in locations) {
//                val loc = point.value
//                val intent = Intent(ACTION_LOCATION_DATA).apply {
//                    putExtra(EXTRA_LATITUDE, loc.latitude)
//                    putExtra(EXTRA_LONGITUDE, loc.longitude)
//                }
//                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
//            }
//        }.onFailure {
//            Log.e(TAG, "Error processing location", it)
//        }
//    }
//}


package com.example.wearapp.presentation

import android.content.Intent
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import androidx.health.services.client.PassiveListenerService
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataType
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.firebase.database.FirebaseDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MyPassiveListenerService : PassiveListenerService() {

    private val TAG = "PassiveListenerService"

    companion object {
        const val ACTION_HEART_RATE_DATA = "com.example.wearapp.HEART_RATE_DATA"
        const val ACTION_LOCATION_DATA = "com.example.wearapp.LOCATION_DATA"
        const val EXTRA_HEART_RATE = "heart_rate"
        //const val EXTRA_HEART_RATE_BPM_STATS = "heart_rate_bpm_stats"
        const val EXTRA_STEPS = "steps"
        const val EXTRA_DISTANCE = "distance_meters"
        const val EXTRA_CALORIES = "calories_kcal"
        const val EXTRA_LATITUDE = "latitude"
        const val EXTRA_LONGITUDE = "longitude"
        const val EXTRA_TIMESTAMP = "timestamp"
    }

    // --- Firebase + ids/sequence ---
    private val db by lazy { FirebaseDatabase.getInstance() }
    private val deviceId by lazy {
        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
    }
    private val prefs by lazy { getSharedPreferences("hr_seq", MODE_PRIVATE) }

    private fun nextReadingNumber(): Int {
        val n = prefs.getInt("reading_seq", 0) + 1
        prefs.edit().putInt("reading_seq", n).apply()
        return n
    }

    private fun sendHeartRateToFirebase(
        heartRate: Double,
        timestamp: Long,
        steps: Long?,
        distanceMeters: Double?,
        caloriesKcal: Double?
    ) {
        val payload = mutableMapOf<String, Any>(
            "timestamp" to timestamp,
            "heartRate" to heartRate,
            "deviceId" to deviceId,
            "readingNumber" to nextReadingNumber()
        ).apply {
            steps?.let { put("steps", it) }
            distanceMeters?.let { put("distanceMeters", it) }
            caloriesKcal?.let { put("caloriesKcal", it) }
        }

        val ref = db.getReference("test_write_health").push()
        CoroutineScope(Dispatchers.IO).launch {
            ref.setValue(payload)
                .addOnSuccessListener { Log.d(TAG, "✅ HR sent: $payload") }
                .addOnFailureListener { e -> Log.e(TAG, "❌ HR send failed", e) }
        }
    }

    private fun sendLocationToFirebase(
        latitude: Double,
        longitude: Double,
        timestamp: Long
    ) {
        val payload = mapOf(
            "timestamp" to timestamp,
            "latitude" to latitude,
            "longitude" to longitude,
            "deviceId" to deviceId
        )
        val ref = db.getReference("test_write_location").push()
        CoroutineScope(Dispatchers.IO).launch {
            ref.setValue(payload)
                .addOnSuccessListener { Log.d(TAG, "✅ Location sent: $payload") }
                .addOnFailureListener { e -> Log.e(TAG, "❌ Location send failed", e) }
        }
    }

    override fun onNewDataPointsReceived(dataPoints: DataPointContainer) {
        Log.d(TAG, "onNewDataPointsReceived: $dataPoints")

        // --- Heart Rate & Metadata ---
        runCatching {
            val hrPoints = dataPoints.getData(DataType.HEART_RATE_BPM)

            // Keep your names/aggregation approach
            val distance = dataPoints.getData(DataType.DISTANCE).lastOrNull()?.value as? Double
            val calories = dataPoints.getData(DataType.CALORIES).lastOrNull()?.value as? Double
            val steps = dataPoints.getData(DataType.STEPS)
                .mapNotNull { it.value as? Long }
                .sum()

            for (point in hrPoints) {
                val bpm = point.value
                val timestamp = System.currentTimeMillis()

                // 1) send directly to Firebase from the service
                sendHeartRateToFirebase(bpm, timestamp, steps, distance, calories)

                // 2) still broadcast for the Activity/UI
                val intent = Intent(ACTION_HEART_RATE_DATA).apply {
                    putExtra(EXTRA_HEART_RATE, bpm)
                    steps?.let { putExtra(EXTRA_STEPS, it) }
                    distance?.let { putExtra(EXTRA_DISTANCE, it) }
                    calories?.let { putExtra(EXTRA_CALORIES, it) }
                    putExtra(EXTRA_TIMESTAMP, timestamp)
                }
                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)

                Log.d(TAG, " HR: $bpm BPM, steps=$steps, dist=$distance, kcal=$calories, timestamp=$timestamp")
            }

        }.onFailure {
            Log.e(TAG, "Error processing HR batch", it)
        }

        // --- Location ---
        runCatching {
            val locations = dataPoints.getData(DataType.LOCATION)
            for (point in locations) {
                val loc = point.value
                val ts = System.currentTimeMillis()

                // send location to Firebase from the service
                sendLocationToFirebase(loc.latitude, loc.longitude, ts)

                // broadcast (optional)
                val intent = Intent(ACTION_LOCATION_DATA).apply {
                    putExtra(EXTRA_LATITUDE, loc.latitude)
                    putExtra(EXTRA_LONGITUDE, loc.longitude)
                    putExtra(EXTRA_TIMESTAMP, ts)
                }
                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
            }
        }.onFailure {
            Log.e(TAG, "Error processing location", it)
        }
    }
}
