package com.example.alert_mate

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.telecom.TelecomManager
import android.Manifest
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import java.util.concurrent.atomic.AtomicBoolean

class PhoneCallHandler(private val context: Context, private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val isCallInProgress = AtomicBoolean(false)
    private val handler = Handler(Looper.getMainLooper())
    private var callTimeout: Runnable? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "makePhoneCall" -> {
                if (isCallInProgress.get()) {
                    result.error("CALL_IN_PROGRESS", "Another call is already in progress", null)
                    return
                }

                val phoneNumber = call.argument<String>("phoneNumber")
                if (phoneNumber != null) {
                    makePhoneCall(phoneNumber, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun makePhoneCall(phoneNumber: String, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CALL_PHONE) 
            == PackageManager.PERMISSION_GRANTED) {
            try {
                if (isCallInProgress.compareAndSet(false, true)) {
                    val intent = Intent(Intent.ACTION_CALL).apply {
                        data = Uri.parse("tel:$phoneNumber")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    // Start the call
                    context.startActivity(intent)

                    // Set up call timeout
                    callTimeout = Runnable {
                        isCallInProgress.set(false)
                    }
                    handler.postDelayed(callTimeout!!, 60000) // 1 minute timeout

                    result.success(true)
                } else {
                    result.error("CALL_IN_PROGRESS", "Another call is already in progress", null)
                }
            } catch (e: Exception) {
                isCallInProgress.set(false)
                result.error("CALL_ERROR", e.message, null)
            }
        } else {
            result.error("PERMISSION_DENIED", "Call phone permission not granted", null)
        }
    }

    fun onCallStateChanged(isCallActive: Boolean) {
        if (!isCallActive) {
            handler.removeCallbacks(callTimeout!!)
            isCallInProgress.set(false)
        }
    }
}