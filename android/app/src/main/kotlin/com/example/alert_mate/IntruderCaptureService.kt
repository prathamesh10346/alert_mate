package com.example.alert_mate

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import android.content.Context

class IntruderCaptureService : Service() {
    private val CHANNEL = "com.example.alert_mate/intruder_detection"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.getBooleanExtra("capture_photo", false) == true) {
            // Wait a short moment to ensure device is fully unlocked
            Handler(Looper.getMainLooper()).postDelayed({
                notifyFlutterToCapturePhoto()
            }, 1000)
        }
        return START_NOT_STICKY
    }

    private fun notifyFlutterToCapturePhoto() {
        val prefs = getSharedPreferences("intruder_prefs", Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean("intruder_selfie_enabled", false)

        if (isEnabled) {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)

            // Give the app a moment to launch before triggering the camera
            Handler(Looper.getMainLooper()).postDelayed({
                IntruderDetectionManager.notifyFailedAttempts(this)
            }, 1500)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}