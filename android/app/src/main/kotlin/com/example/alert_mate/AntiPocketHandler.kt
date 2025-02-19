package com.example.alert_mate

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager


class AntiPocketHandler(private val context: Context, private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val isAlarmActive = AtomicBoolean(false)
    private var audioManager: AudioManager? = null
    private var mediaPlayer: MediaPlayer? = null
    private var originalVolume: Int = 0
    private val handler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "disableHardwareButtons" -> {
                try {
                    disableHardwareButtons()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("HARDWARE_CONTROL_ERROR", e.message, null)
                }
            }
            "enableHardwareButtons" -> {
                try {
                    enableHardwareButtons()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("HARDWARE_CONTROL_ERROR", e.message, null)
                }
            }
            "startAlarm" -> {
                if (isAlarmActive.get()) {
                    result.error("ALARM_IN_PROGRESS", "Alarm is already active", null)
                    return
                }
                try {
                    startAlarm()
                    result.success(true)
                } catch (e: Exception) {
                    isAlarmActive.set(false)
                    result.error("ALARM_ERROR", e.message, null)
                }
            }
            "stopAlarm" -> {
                try {
                    stopAlarm()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ALARM_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun disableHardwareButtons() {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.MODIFY_AUDIO_SETTINGS) 
            == PackageManager.PERMISSION_GRANTED) {
            audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            originalVolume = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
            audioManager?.setStreamVolume(
                AudioManager.STREAM_MUSIC,
                audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 0,
                0
            )
        }
    }

    private fun enableHardwareButtons() {
        audioManager?.setStreamVolume(
            AudioManager.STREAM_MUSIC,
            originalVolume,
            0
        )
    }

    private fun startAlarm() {
        if (isAlarmActive.compareAndSet(false, true)) {
            val intent = Intent(context, AlarmService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            try {
                registerScreenOffReceiver()
                // Initialize and start MediaPlayer
                mediaPlayer = MediaPlayer().apply {
                    // Get the resource ID for the alarm sound
                    val resId = context.resources.getIdentifier(
                        "alarm",  // Name of your sound file without extension
                        "raw",
                        context.packageName
                    )
                    if (resId == 0) {
                        throw Exception("Alarm sound resource not found")
                    }
                    setDataSource(context, android.net.Uri.parse("android.resource://${context.packageName}/$resId"))
                    prepare()
                    setLooping(true)
                    start()
                }

                // Start vibration
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createWaveform(
                        longArrayOf(500, 1000),
                        intArrayOf(255, 0),
                        0
                    ))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(longArrayOf(500, 1000), 0)
                }
            } catch (e: Exception) {
                isAlarmActive.set(false)
                throw e
            }
        }
    }
    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF && isAlarmActive.get()) {
                val powerManager = context?.getSystemService(Context.POWER_SERVICE) as PowerManager
                val wakeLock = powerManager.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "AntiPocketHandler:WakeLock"
                )
                wakeLock.acquire(3000) // Wake the screen for 3 seconds
            }
        }
    }
    fun registerScreenOffReceiver() {
        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        context.registerReceiver(screenOffReceiver, filter)
    }
    fun unregisterScreenOffReceiver() {
        try {
            context.unregisterReceiver(screenOffReceiver)
        } catch (e: Exception) {
            // Handle receiver not registered
        }
    }
    private fun stopAlarm() {
        if (isAlarmActive.compareAndSet(true, false)) {
            // Stop and release MediaPlayer
            unregisterScreenOffReceiver()
            val intent = Intent(context, AlarmService::class.java)
            context.stopService(intent)
            mediaPlayer?.apply {
                try {
                    if (isPlaying) {
                        stop()
                    }
                } catch (e: Exception) {
                    // Handle any MediaPlayer errors
                } finally {
                    release()
                }
            }
            mediaPlayer = null

            // Stop vibration
            val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator.cancel()

            // Reset audio settings
            enableHardwareButtons()
        }
    }

    fun cleanup() {
        stopAlarm()
        handler.removeCallbacksAndMessages(null)
    }

    fun isAlarmCurrentlyActive(): Boolean {
        return isAlarmActive.get()
    }
}