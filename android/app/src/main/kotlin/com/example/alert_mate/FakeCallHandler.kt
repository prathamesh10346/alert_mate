// FakeCallHandler.kt
package com.example.alert_mate

import android.app.Activity
import android.content.Context
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.WindowManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FakeCallHandler(
    private val context: Context,
    private val activity: Activity
) : MethodChannel.MethodCallHandler {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "simulateFakeCall" -> {
                simulateFakeCall()
                result.success(null)
            }
            "stopFakeCall" -> {
                stopFakeCall()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun simulateFakeCall() {
        // Keep screen on during fake call
        activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Play default ringtone
        val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        mediaPlayer = MediaPlayer.create(context, ringtoneUri).apply {
            isLooping = true
            start()
        }

        // Vibrate phone
        vibrator = (context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).apply {
            val pattern = longArrayOf(0, 1000, 1000)
            vibrate(VibrationEffect.createWaveform(pattern, 0))
        }

        // Stop after 30 seconds
        handler.postDelayed({
            stopFakeCall()
        }, 10000)
    }

    private fun stopFakeCall() {
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null

        vibrator?.cancel()
        vibrator = null

        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    fun cleanup() {
        stopFakeCall()
        handler.removeCallbacksAndMessages(null)
    }
}