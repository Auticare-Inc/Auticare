//package com.example.wearapp.presentation
//
//import android.content.Context
//import android.util.Log
//import androidx.health.services.client.HealthServices
//import androidx.health.services.client.HealthServicesException
//import androidx.health.services.client.PassiveMonitoringClient
//import androidx.health.services.client.data.DataType
//import androidx.health.services.client.data.PassiveListenerConfig
//import kotlinx.coroutines.guava.await
//
//class HealthServiceManager(private val context: Context) {
//
//    private val passiveMonitoringClient: PassiveMonitoringClient =
//        HealthServices.getClient(context).passiveMonitoringClient
//    private val TAG = "HealthServiceManager"
//
//    suspend fun startHealthMonitoring(): Boolean {
//        return try {
//            if (!isHealthServicesAvailable()) {
//                Log.e(TAG, "Health Services not available on this device")
//                return false
//            }
//
//            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
//            val supportedDataTypes = capabilities.supportedDataTypesPassiveMonitoring
//
//            Log.d(TAG, "Supported passive data types: ${supportedDataTypes.map { it.name }}")
//
//            // Check which data types are supported
//            val requestedDataTypes = mutableSetOf<DataType<*, *>>()
//
//            if (supportedDataTypes.contains(DataType.HEART_RATE_BPM)) {
//                requestedDataTypes.add(DataType.HEART_RATE_BPM)
//                Log.d(TAG, "Heart rate monitoring will be enabled")
//            } else {
//                Log.w(TAG, "Heart rate monitoring not supported on this device")
//            }
//
//            if (supportedDataTypes.contains(DataType.LOCATION)) {
//                requestedDataTypes.add(DataType.LOCATION)
//                Log.d(TAG, "Location monitoring will be enabled")
//            } else {
//                Log.w(TAG, "Location monitoring not supported on this device")
//            }
//
//            if (requestedDataTypes.isEmpty()) {
//                Log.e(TAG, "No supported data types available")
//                return false
//            }
//
//            // Create config with supported data types
//            val config = PassiveListenerConfig.builder()
//                .setDataTypes(requestedDataTypes)
//                .setShouldUserActivityInfoBeRequested(false)
//                .build()
//
//            passiveMonitoringClient.setPassiveListenerServiceAsync(
//                MyPassiveListenerService::class.java,
//                config
//            ).await()
//
//            Log.d(TAG, "Successfully started passive monitoring for: ${requestedDataTypes.map { it.name }}")
//            true
//
//        } catch (e: HealthServicesException) {
//            Log.e(TAG, "Health Services Exception: ${e.message}", e)
//            false
//        } catch (e: SecurityException) {
//            Log.e(TAG, "Permission denied - ensure required permissions are granted", e)
//            false
//        } catch (e: Exception) {
//            Log.e(TAG, "Unexpected error starting monitoring", e)
//            false
//        }
//    }
//
//    suspend fun stopMonitoring(): Boolean {
//        return try {
//            passiveMonitoringClient.clearPassiveListenerServiceAsync().await()
//            Log.d(TAG, "Stopped monitoring")
//            true
//        } catch (e: Exception) {
//            Log.e(TAG, "Error stopping monitoring", e)
//            false
//        }
//    }
//
//    private fun isHealthServicesAvailable(): Boolean {
//        return try {
//            HealthServices.getClient(context) != null
//        } catch (e: Exception) {
//            Log.e(TAG, "Health Services not available", e)
//            false
//        }
//    }
//
//    suspend fun isHeartRateSupported(): Boolean {
//        return try {
//            if (!isHealthServicesAvailable()) return false
//
//            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
//            val isSupported = capabilities.supportedDataTypesPassiveMonitoring.contains(DataType.HEART_RATE_BPM)
//            Log.d(TAG, "Heart rate monitoring supported: $isSupported")
//            isSupported
//        } catch (e: Exception) {
//            Log.e(TAG, "Error checking heart rate support", e)
//            false
//        }
//    }
//
//    suspend fun isLocationSupported(): Boolean {
//        return try {
//            if (!isHealthServicesAvailable()) return false
//
//            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
//            val isSupported = capabilities.supportedDataTypesPassiveMonitoring.contains(DataType.LOCATION)
//            Log.d(TAG, "Location monitoring supported: $isSupported")
//            isSupported
//        } catch (e: Exception) {
//            Log.e(TAG, "Error checking location support", e)
//            false
//        }
//    }
//
//    suspend fun getAvailableDataTypes(): Set<DataType<*, *>> {
//        return try {
//            if (!isHealthServicesAvailable()) return emptySet()
//
//            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
//            Log.d(TAG, "Available passive monitoring data types:")
//            capabilities.supportedDataTypesPassiveMonitoring.forEach { dataType ->
//                Log.d(TAG, "- ${dataType.name}")
//            }
//            capabilities.supportedDataTypesPassiveMonitoring
//        } catch (e: Exception) {
//            Log.e(TAG, "Error getting capabilities", e)
//            emptySet()
//        }
//    }
//}

package com.example.wearapp.presentation

import android.content.Context
import android.util.Log
import androidx.health.services.client.HealthServices
import androidx.health.services.client.HealthServicesException
import androidx.health.services.client.PassiveMonitoringClient
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.PassiveListenerConfig
import kotlinx.coroutines.guava.await

class HealthServiceManager(private val context: Context) {

    private val passiveMonitoringClient: PassiveMonitoringClient =
        HealthServices.getClient(context).passiveMonitoringClient
    private val TAG = "HealthServiceManager"

    suspend fun startHealthMonitoring(): Boolean {
        return try {
            if (!isHealthServicesAvailable()) {
                Log.e(TAG, "Health Services not available on this device")
                return false
            }

            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
            val supported = capabilities.supportedDataTypesPassiveMonitoring

            Log.d(TAG, "Supported passive data types: ${supported.map { it.name }}")

            val requested = linkedSetOf<DataType<*, *>>()

            // Helper to add if supported (and log)
            fun addIfSupported(dt: DataType<*, *>, label: String = dt.name) {
                if (supported.contains(dt)) {
                    requested.add(dt)
                    Log.d(TAG, "$label will be enabled")
                } else {
                    Log.w(TAG, "$label not supported on this device")
                }
            }

            // Heart rate
            addIfSupported(DataType.HEART_RATE_BPM, "Heart rate monitoring")

            // Steps / Distance / Calories (delta)
            addIfSupported(DataType.STEPS, "Steps")
            addIfSupported(DataType.DISTANCE, "Distance")
            addIfSupported(DataType.CALORIES, "Calories")

            // Location (optional)
            addIfSupported(DataType.LOCATION, "Location monitoring")

            if (requested.isEmpty()) {
                Log.e(TAG, "No supported data types available")
                return false
            }

            val config = PassiveListenerConfig.builder()
                .setDataTypes(requested)
                .setShouldUserActivityInfoBeRequested(false)
                .build()

            passiveMonitoringClient.setPassiveListenerServiceAsync(
                MyPassiveListenerService::class.java,
                config
            ).await()

            Log.d(TAG, "Successfully started passive monitoring for: ${requested.map { it.name }}")
            true

        } catch (e: HealthServicesException) {
            Log.e(TAG, "Health Services Exception: ${e.message}", e)
            false
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied - ensure required permissions are granted", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error starting monitoring", e)
            false
        }
    }

    suspend fun stopMonitoring(): Boolean {
        return try {
            passiveMonitoringClient.clearPassiveListenerServiceAsync().await()
            Log.d(TAG, "Stopped monitoring")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping monitoring", e)
            false
        }
    }

    private fun isHealthServicesAvailable(): Boolean {
        return try {
            HealthServices.getClient(context) != null
        } catch (e: Exception) {
            Log.e(TAG, "Health Services not available", e)
            false
        }
    }

    suspend fun isHeartRateSupported(): Boolean {
        return try {
            if (!isHealthServicesAvailable()) return false
            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
            val isSupported = capabilities.supportedDataTypesPassiveMonitoring.contains(DataType.HEART_RATE_BPM)
            Log.d(TAG, "Heart rate monitoring supported: $isSupported")
            isSupported
        } catch (e: Exception) {
            Log.e(TAG, "Error checking heart rate support", e)
            false
        }
    }

    suspend fun isLocationSupported(): Boolean {
        return try {
            if (!isHealthServicesAvailable()) return false
            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
            val isSupported = capabilities.supportedDataTypesPassiveMonitoring.contains(DataType.LOCATION)
            Log.d(TAG, "Location monitoring supported: $isSupported")
            isSupported
        } catch (e: Exception) {
            Log.e(TAG, "Error checking location support", e)
            false
        }
    }

    suspend fun getAvailableDataTypes(): Set<DataType<*, *>> {
        return try {
            if (!isHealthServicesAvailable()) return emptySet()
            val capabilities = passiveMonitoringClient.getCapabilitiesAsync().await()
            Log.d(TAG, "Available passive monitoring data types:")
            capabilities.supportedDataTypesPassiveMonitoring.forEach { dataType ->
                Log.d(TAG, "- ${dataType.name}")
            }
            capabilities.supportedDataTypesPassiveMonitoring
        } catch (e: Exception) {
            Log.e(TAG, "Error getting capabilities", e)
            emptySet()
        }
    }
}
