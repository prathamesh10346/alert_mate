package com.example.alert_mate

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.telephony.TelephonyManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SimMonitorHandler(
    private val context: Context,
    private val activity: Activity
) : MethodCallHandler {
    private var isMonitoring = false
    private var channel: MethodChannel? = null

    private val simStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "android.intent.action.SIM_STATE_CHANGED") {
                try {
                    val telephonyManager = context?.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    val simState = telephonyManager.simState
                    val simOperator = getSimOperator()
                    
                    activity.runOnUiThread {
                        channel?.invokeMethod("onSimChanged", mapOf(
                            "simState" to simState,
                            "simOperator" to simOperator
                        ))
                    }
                } catch (e: Exception) {
                    println("Error in simStateReceiver: ${e.message}")
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startSimMonitoring" -> {
                startMonitoring()
                result.success(getSimInfo())
            }
            "stopMonitoring" -> {
                stopMonitoring()
                result.success(true)
            }
            "getSimInfo" -> {
                result.success(getSimInfo())
            }
            else -> result.notImplemented()
        }
    }

    private fun startMonitoring() {
        if (!isMonitoring) {
            try {
                context.registerReceiver(
                    simStateReceiver,
                    IntentFilter("android.intent.action.SIM_STATE_CHANGED")
                )
                isMonitoring = true
            } catch (e: Exception) {
                println("Error starting monitoring: ${e.message}")
            }
        }
    }

    private fun stopMonitoring() {
        if (isMonitoring) {
            try {
                context.unregisterReceiver(simStateReceiver)
                isMonitoring = false
            } catch (e: Exception) {
                println("Error stopping monitoring: ${e.message}")
            }
        }
    }

    private fun getSimOperator(): String {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        return telephonyManager.simOperator ?: "Unknown"
    }

    private fun getSimInfo(): Map<String, Any> {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        return mapOf(
            "simState" to (telephonyManager.simState == TelephonyManager.SIM_STATE_READY),
            "simOperator" to (telephonyManager.simOperator ?: "Unknown"),
            "simCountryIso" to (telephonyManager.simCountryIso ?: "Unknown"),
            "simOperatorName" to (telephonyManager.simOperatorName ?: "Unknown")
        )
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.channel = channel
    }

    fun cleanup() {
        stopMonitoring()
    }
}