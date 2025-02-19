// SmsHandler.kt
package com.example.alert_mate

import android.content.Context
import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.telephony.SmsManager
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class SmsHandler(private val context: Context, private val activity: Activity) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sendSMS" -> {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                
                if (phoneNumber != null && message != null) {
                    sendSMS(phoneNumber, message, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number and message are required", null)
                }
            }
            "sendMediaFiles" -> {
                val phoneNumber = call.argument<String>("phoneNumber")
                val filePaths = call.argument<List<String>>("filePaths")
                
                if (phoneNumber != null && filePaths != null) {
                    sendMediaFiles(phoneNumber, filePaths, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number and file paths are required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun sendSMS(phoneNumber: String, message: String, result: MethodChannel.Result) {
        try {
            val smsManager = SmsManager.getDefault()
            val sentIntent = PendingIntent.getBroadcast(
                context, 0, Intent("SMS_SENT"),
                PendingIntent.FLAG_IMMUTABLE
            )

            val messageParts = smsManager.divideMessage(message)
            val sentIntents = ArrayList<PendingIntent>()
            repeat(messageParts.size) {
                sentIntents.add(sentIntent)
            }

            smsManager.sendMultipartTextMessage(
                phoneNumber,
                null,
                messageParts,
                sentIntents,
                null
            )
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SMS_ERROR", e.message, null)
        }
    }
    private fun sendMediaFiles(phoneNumber: String, filePaths: List<String>, result: MethodChannel.Result) {
        try {
            val mediaUris = ArrayList<Uri>()
            for (path in filePaths) {
                val file = File(path)
                if (file.exists()) {
                    val uri = FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.provider",
                        file
                    )
                    mediaUris.add(uri)
                }
            }
    
            if (mediaUris.isNotEmpty()) {
                val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                    type = "*/*"
                    putExtra(Intent.EXTRA_PHONE_NUMBER, phoneNumber)
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, mediaUris)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                
                context.startActivity(Intent.createChooser(intent, "Share media files")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("MEDIA_SHARE_ERROR", e.message, null)
        }
    }
}