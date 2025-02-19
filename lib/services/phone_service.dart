import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PhoneService {
    static const platform = MethodChannel('com.your.app/phone_call');

  static Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      final bool result = await platform.invokeMethod('makePhoneCall', {
        'phoneNumber': phoneNumber,
      });
      return result;
    } on PlatformException catch (e) {
      print('Error making phone call: ${e.message}');
      return false;
    }
  }
  Future<Map<String, String>> getPhoneAndBatteryInfo() async {
    try {
      var status = await Permission.phone.request();
      if (!status.isGranted) {
        return {
          'Phone Number': 'Permission denied',
          'Battery Level': 'Permission denied'
        };
      }

      Map<String, String> simDetails = {};

     
      // Get platform version (since direct battery level is not available)
  

      return simDetails;
    } catch (e) {
      print('Error getting phone and battery info: $e');
      return {
        'Error': 'Failed to get phone and battery information: $e'
      };
    }
  }
}