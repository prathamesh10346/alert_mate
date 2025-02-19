import 'package:flutter/services.dart';

class BluetoothProximityService {
  static const MethodChannel _channel =
      MethodChannel('com.your.app/bluetooth_proximity');

  static Future<void> startProximityMonitoring() async {
    try {
      await _channel.invokeMethod('startMonitoring');
    } catch (e) {
      print('Error starting proximity monitoring: $e');
    }
  }

  static Future<void> stopProximityMonitoring() async {
    try {
      await _channel.invokeMethod('stopMonitoring');
    } catch (e) {
      print('Error stopping proximity monitoring: $e');
    }
  }

  static void setupProximityListeners({
    required Function(List<dynamic>) onDevicesUpdate,
    required Function(Map<String, dynamic>) onProximityAlert,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'updateDevices':
          onDevicesUpdate(call.arguments);
          break;
        case 'proximityAlert':
          onProximityAlert(call.arguments);
          break;
      }
      return null;
    });
  }
}
