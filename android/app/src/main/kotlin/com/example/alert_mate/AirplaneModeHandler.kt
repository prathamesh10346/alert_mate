// AirplaneModeHandler.kt
package com.example.alert_mate

import android.content.Context
import android.provider.Settings
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.app.Activity

class AirplaneModeHandler(private val context: Context, private val activity: Activity) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "disableAirplaneMode" -> {
                try {
                    
                    Settings.Global.putInt(
                        context.contentResolver,
                        Settings.Global.AIRPLANE_MODE_ON,
                        0
                    )

                    // Broadcast the change
                    val intent = Intent(Intent.ACTION_AIRPLANE_MODE_CHANGED)
                    intent.putExtra("state", false)
                    context.sendBroadcast(intent)
                    
                    result.success(true)
                } catch (e: Exception) {
                    result.error("AIRPLANE_MODE_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}