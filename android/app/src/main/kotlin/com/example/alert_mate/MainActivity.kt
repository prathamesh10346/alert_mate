package com.example.alert_mate
import android.Manifest
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.view.KeyEvent
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var antiPocketHandler: AntiPocketHandler
    private lateinit var simMonitorHandler: SimMonitorHandler
    private lateinit var bluetoothProximityHandler: BluetoothProximityHandler

    companion object {
        private const val BLUETOOTH_PERMISSION_REQUEST_CODE = 1001
        private val BLUETOOTH_PERMISSIONS = arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check and request Bluetooth permissions if not granted
        if (!hasBluetoothPermissions()) {
            requestBluetoothPermissions()
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize the anti-pocket handler
        antiPocketHandler = AntiPocketHandler(applicationContext, this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.your.app/device_control")
            .setMethodCallHandler(antiPocketHandler)
        
            val bluetoothProximityHandler = BluetoothProximityHandler(applicationContext)
            val bluetoothProximityChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger, 
                "com.your.app/bluetooth_proximity"
            )
            bluetoothProximityHandler.setMethodChannel(bluetoothProximityChannel)
            bluetoothProximityChannel.setMethodCallHandler(bluetoothProximityHandler)

        // Other existing method channels
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.your.app/phone_call")
            .setMethodCallHandler(PhoneCallHandler(applicationContext, this))     
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.your.app/fake_call")
            .setMethodCallHandler(FakeCallHandler(applicationContext, this))
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.your.app/sms")
            .setMethodCallHandler(SmsHandler(applicationContext, this))
        
        // Initialize sim monitor handler
        simMonitorHandler = SimMonitorHandler(applicationContext, this)
        
        // Create and set up the method channel for sim monitoring
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.your.app/sim_monitor")
        simMonitorHandler.setMethodChannel(channel)
        channel.setMethodCallHandler(simMonitorHandler)
    }

    private fun hasBluetoothPermissions(): Boolean {
        return BLUETOOTH_PERMISSIONS.all { permission ->
            ContextCompat.checkSelfPermission(
                this,
                permission
            ) == PackageManager.PERMISSION_GRANTED
        }
    }
    private fun requestBluetoothPermissions() {
        // For Android 6.0 (Marshmallow) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ActivityCompat.requestPermissions(
                this,
                BLUETOOTH_PERMISSIONS,
                BLUETOOTH_PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == BLUETOOTH_PERMISSION_REQUEST_CODE) {
            // Check if all permissions are granted
            val allPermissionsGranted = grantResults.all { 
                it == PackageManager.PERMISSION_GRANTED 
            }
            
            if (!allPermissionsGranted) {
                // Handle case where not all permissions are granted
                // You might want to show a dialog explaining why permissions are needed
            }
        }
    }
    // Existing methods remain the same
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return if (antiPocketHandler.isAlarmCurrentlyActive() && 
                  (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || 
                   keyCode == KeyEvent.KEYCODE_VOLUME_UP || 
                   keyCode == KeyEvent.KEYCODE_POWER)) {
            true // Consume the event
        } else {
            super.onKeyDown(keyCode, event)
        }
    }

    override fun onBackPressed() {
        if (antiPocketHandler.isAlarmCurrentlyActive()) {
            // Prevent back button during alarm
            return
        }
        super.onBackPressed()
    }
    
    override fun onUserLeaveHint() {
        if (antiPocketHandler.isAlarmCurrentlyActive()) {
            // Prevent user from minimizing the app
            return
        }
        super.onUserLeaveHint()
    }

    override fun onDestroy() {
        antiPocketHandler.cleanup()
        simMonitorHandler.cleanup()
        super.onDestroy()
    }
}