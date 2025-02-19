// sms_service.dart
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  static const platform = MethodChannel('com.your.app/sms');

  static Future<bool> sendSMS(String phoneNumber, String message) async {
    try {
      if (await Permission.sms.isGranted) {
        final bool result = await platform.invokeMethod('sendSMS', {
          'phoneNumber': phoneNumber,
          'message': message,
        });
        return result;
      }
      return false;
    } on PlatformException catch (e) {
      print('Error sending SMS: ${e.message}');
      return false;
    }
  }

  static Future<bool> sendMediaFiles(String phoneNumber, List<String> filePaths) async {
    try {
      if (await Permission.sms.isGranted) {
        final bool result = await platform.invokeMethod('sendMediaFiles', {
          'phoneNumber': phoneNumber,
          'filePaths': filePaths,
        });
        return result;
      }
      return false;
    } on PlatformException catch (e) {
      print('Error sending media files: ${e.message}');
      return false;
    }
  }

  static Future<bool> sendEmergencySMS(
      List<String> phoneNumbers, String message, [List<String>? mediaFiles]) async {
    bool atLeastOneSent = false;

    for (final phoneNumber in phoneNumbers) {
      try {
        final success = await sendSMS(phoneNumber, message);
        if (mediaFiles != null && mediaFiles.isNotEmpty) {
          await sendMediaFiles(phoneNumber, mediaFiles);
        }
        if (success) {
          atLeastOneSent = true;
        }
      } catch (e) {
        print('Failed to send SMS to $phoneNumber: $e');
      }
    }

    return atLeastOneSent;
  }
}