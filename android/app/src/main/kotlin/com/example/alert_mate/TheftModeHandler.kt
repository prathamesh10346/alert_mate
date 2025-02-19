// class TheftModeHandler(
//     private val context: Context,
//     private val activity: Activity
// ) : MethodChannel.MethodCallHandler {
//     private var isTheftModeEnabled = false
//     private val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
//     private val componentName = ComponentName(context, DeviceAdminReceiver::class.java)
//     private val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
//     private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
//     private val firebaseMessaging = FirebaseMessaging.getInstance()

//     private val deviceId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)

//     override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//         when (call.method) {
//             "toggleTheftMode" -> {
//                 val enabled = call.argument<Boolean>("enabled") ?: false
//                 toggleTheftMode(enabled)
//                 updateServerStatus(enabled)
//                 result.success(null)
//             }
//             "getTheftModeStatus" -> {
//                 result.success(isTheftModeEnabled)
//             }
//             "unlockDevice" -> {
//                 val token = call.argument<String>("token")
//                 if (verifyUnlockToken(token)) {
//                     disableTheftMode()
//                     result.success(true)
//                 } else {
//                     result.error("INVALID_TOKEN", "Invalid unlock token", null)
//                 }
//             }
//             else -> result.notImplemented()
//         }
//     }

//     private fun toggleTheftMode(enabled: Boolean) {
//         if (enabled) {
//             if (devicePolicyManager.isAdminActive(componentName)) {
//                 isTheftModeEnabled = true
//                 startTheftMode()
//             } else {
//                 requestAdminPrivileges()
//             }
//         } else {
//             disableTheftMode()
//         }
//     }

//     private fun startTheftMode() {
//         disableFeatures()
//         startAlarmService()
//         registerFirebaseToken()
//         devicePolicyManager.lockNow()
//     }

//     private fun disableFeatures() {
//         // Disable Wi-Fi
//         wifiManager.isWifiEnabled = false

//         // Disable mobile data
//         val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
//         connectivityManager.restrictBackground(true)

//         // Set volume to silent
//         audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT

//         // Disable USB debugging
//         Settings.Global.putInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0)

//         // Set maximum screen lock timeout
//         devicePolicyManager.setMaximumTimeToLock(componentName, 0)

//         // Disable camera
//         devicePolicyManager.setCameraDisabled(componentName, true)

//         // Start location tracking
//         startLocationTracking()
//     }

//     private fun disableTheftMode() {
//         isTheftModeEnabled = false
//         enableFeatures()
//         stopAlarmService()
//         updateServerStatus(false)
//     }

//     private fun enableFeatures() {
//         // Re-enable Wi-Fi
//         wifiManager.isWifiEnabled = true

//         // Re-enable mobile data
//         val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
//         connectivityManager.restrictBackground(false)

//         // Restore audio settings
//         audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL

//         // Re-enable camera
//         devicePolicyManager.setCameraDisabled(componentName, false)

//         // Stop location tracking
//         stopLocationTracking()
//     }

//     private fun updateServerStatus(enabled: Boolean) {
//         val retrofit = RetrofitClient.getInstance()
//         val apiService = retrofit.create(ApiService::class.java)

//         CoroutineScope(Dispatchers.IO).launch {
//             try {
//                 apiService.updateDeviceStatus(
//                     DeviceStatus(
//                         deviceId = deviceId,
//                         theftModeEnabled = enabled,
//                         location = getLastKnownLocation(),
//                         batteryLevel = getBatteryLevel(),
//                         timestamp = System.currentTimeMillis()
//                     )
//                 )
//             } catch (e: Exception) {
//                 Log.e("TheftMode", "Failed to update server status", e)
//             }
//         }
//     }

//     private fun verifyUnlockToken(token: String?): Boolean {
//         if (token == null) return false
//         return try {
//             // Verify token with your backend server
//             val response = apiService.verifyUnlockToken(deviceId, token).execute()
//             response.isSuccessful
//         } catch (e: Exception) {
//             false
//         }
//     }
// }