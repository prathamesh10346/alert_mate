// MonitorService.kt
package com.example.alert_mate

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import java.io.DataOutputStream

class MonitorService : Service() {
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_AIRPLANE_MODE_CHANGED -> {
                    executeCommand("settings put global airplane_mode_on 0")
                    executeCommand("am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false")
                }
                "android.net.wifi.WIFI_STATE_CHANGED" -> {
                    executeCommand("svc wifi enable")
                }
                "android.net.conn.CONNECTIVITY_CHANGE" -> {
                    executeCommand("svc data enable")
                }
            }
        }
    }

    private fun executeCommand(command: String) {
        try {
            val process = Runtime.getRuntime().exec("su")
            val os = DataOutputStream(process.outputStream)
            os.writeBytes("$command\n")
            os.writeBytes("exit\n")
            os.flush()
            process.waitFor()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onCreate() {
        super.onCreate()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_AIRPLANE_MODE_CHANGED)
            addAction("android.net.wifi.WIFI_STATE_CHANGED")
            addAction("android.net.conn.CONNECTIVITY_CHANGE")
        }
        registerReceiver(receiver, filter)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}