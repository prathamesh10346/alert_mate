package com.example.alert_mate

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.os.UserHandle
import android.content.SharedPreferences

class DeviceAdmin : DeviceAdminReceiver() {
    companion object {
        private const val MAX_ATTEMPTS = 3
    }

    override fun onPasswordFailed(context: Context, intent: Intent, user: UserHandle) {
        super.onPasswordFailed(context, intent, user)
        
        val prefs: SharedPreferences = context.getSharedPreferences("intruder_prefs", Context.MODE_PRIVATE)
        val currentAttempts = prefs.getInt("failed_attempts", 0) + 1
        
        prefs.edit().putInt("failed_attempts", currentAttempts).apply()

        if (currentAttempts >= MAX_ATTEMPTS) {
            val captureIntent = Intent(context, CameraService::class.java)
            captureIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startService(captureIntent)
            
            // Reset counter
            prefs.edit().putInt("failed_attempts", 0).apply()
        }
    }

    override fun onPasswordSucceeded(context: Context, intent: Intent, user: UserHandle) {
        super.onPasswordSucceeded(context, intent, user)
        val prefs: SharedPreferences = context.getSharedPreferences("intruder_prefs", Context.MODE_PRIVATE)
        prefs.edit().putInt("failed_attempts", 0).apply()
    }
}