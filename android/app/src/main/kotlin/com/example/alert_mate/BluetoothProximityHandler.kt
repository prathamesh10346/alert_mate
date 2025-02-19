package com.example.alert_mate

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.LinkedList
import java.util.UUID
import kotlin.math.pow
import kotlin.random.Random

class BluetoothProximityHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private var methodChannel: MethodChannel? = null
    private var isMonitoring = false
    private val handler = Handler(Looper.getMainLooper())
    private val monitoringInterval = 5000L // 5 seconds
    private val maxAllowedDistance = 1.0 // meters
    private val rssiBuffer = mutableMapOf<String, LinkedList<Int>>()
    private val rssiBufferSize = 5


    // Standard Serial Port Service UUID
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    companion object {
         private const val RSSI_REF = -69.0 // Calibrate this value for your setup!
        private const val PATH_LOSS_EXPONENT = 2.5 // Calibrate this value for your setup!
    }

    fun setMethodChannel(channel: MethodChannel) {
        methodChannel = channel
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startMonitoring" -> {
                if (!checkBluetoothPermissions()) {
                    result.error("PERMISSION_DENIED", "Bluetooth permissions not granted", null)
                    return
                }
                startProximityMonitoring()
                result.success(true)
            }
            "stopMonitoring" -> {
                stopProximityMonitoring()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkBluetoothPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startProximityMonitoring() {
        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) return

        isMonitoring = true
        handler.post(object : Runnable {
            override fun run() {
                if (!isMonitoring) return

                val pairedDevices = getPairedDevices()
                val deviceInfoList = pairedDevices.map { device ->
                    val rssi = getRssiForDevice()
                    addRssiReading(device.address, rssi)

                    val avgRssi = getAveragedRssi(device.address)

                    val distance = calculateDistance(avgRssi)
                     val isConnected =  checkConnection(device)
                    mapOf(
                        "name" to (device.name ?: "Unknown Device"),
                        "address" to device.address,
                        "distance" to distance,
                        "signalStrength" to rssi,
                        "isConnected" to isConnected
                    )
                }

                // Send device list to Flutter
                methodChannel?.invokeMethod("updateDevices", deviceInfoList)

                // Check for proximity alerts
                deviceInfoList.forEach { deviceInfo ->
                    val distance = deviceInfo["distance"] as Double
                    if (distance > maxAllowedDistance) {
                        methodChannel?.invokeMethod("proximityAlert", deviceInfo)
                    }
                }

                handler.postDelayed(this, monitoringInterval)
            }
        })
    }

     private fun checkConnection(device: BluetoothDevice): Boolean {
        var socket: BluetoothSocket? = null
        try {
             if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) != PackageManager.PERMISSION_GRANTED
                ) return false

            socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
             socket.connect() // attempt to connect
           return socket.isConnected;

        }
        catch (e: Exception) {
          return false;
         } finally {
            try {
               socket?.close()
             } catch (closeException: IOException) {

            }
         }
    }
      private fun addRssiReading(address: String, rssi: Int) {
        if (!rssiBuffer.containsKey(address)) {
            rssiBuffer[address] = LinkedList()
        }
        val readings = rssiBuffer[address]!!
        readings.add(rssi)
        if (readings.size > rssiBufferSize) {
           readings.removeFirst()
        }
    }

     private fun getAveragedRssi(address: String): Int {
          if (!rssiBuffer.containsKey(address)) return -100
        val readings = rssiBuffer[address]!!
        if (readings.isEmpty()) return -100
        return readings.average().toInt()
    }


    private fun stopProximityMonitoring() {
        isMonitoring = false
        handler.removeCallbacksAndMessages(null)
    }

    private fun getPairedDevices(): List<BluetoothDevice> {
        return if (checkBluetoothPermissions()) {
            bluetoothAdapter?.bondedDevices?.toList() ?: emptyList()
        } else {
            emptyList()
        }
    }

    private fun getRssiForDevice(): Int {
        // Simulate RSSI value between -90 and -50
        return Random.nextInt(-90, -50)
    }

    private fun calculateDistance(rssi: Int): Double {
        return 10.0.pow((RSSI_REF - rssi) / (10.0 * PATH_LOSS_EXPONENT))
    }
}