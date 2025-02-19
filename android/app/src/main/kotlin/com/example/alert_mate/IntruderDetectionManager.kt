// IntruderDetectionManager.kt
package com.example.alert_mate

import android.content.Context
import android.hardware.camera2.CameraManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import android.app.KeyguardManager
import android.content.SharedPreferences

class IntruderDetectionManager(private val context: Context) {
    companion object {
        private var methodChannel: MethodChannel? = null
        private val handler = Handler(Looper.getMainLooper())

        fun initialize(channel: MethodChannel) {
            methodChannel = channel
        }

        fun notifyFailedAttempts(context: Context) {
            val prefs = context.getSharedPreferences("intruder_prefs", Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean("intruder_selfie_enabled", false)

            if (isEnabled) {
                handler.post {
                    methodChannel?.invokeMethod("onFailedAttempt", null)
                }
            }
        }
    }
}