import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:alert_mate/services/sms_service.dart';
import 'package:alert_mate/services/email_service.dart';
import 'package:alert_mate/services/camera_service.dart';
import 'package:alert_mate/services/audio_service.dart';

class SOSService {
  final AudioService _audioService = AudioService();
  final CameraService _cameraService = CameraService();
  Timer? _sosTimer;
  List<String> _capturedMedia = [];
  Position? _currentPosition;

  Future<List<String>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('emergency_contacts') ?? [];
  }

  Future<String?> getEmergencyEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('emergency_email');
  }

  Future<void> activateSOS(Position position) async {
    _currentPosition = position;
    final emergencyContacts = await getEmergencyContacts();
    final emergencyEmail = await getEmergencyEmail();

    if (emergencyContacts.isEmpty) {
      throw Exception('No emergency contacts found');
    }

    try {
      // Initialize services
      await _cameraService.initialize();
      await _audioService.initialize();

      // Capture media
      _capturedMedia = await _cameraService.startPeriodicCapture();

      // Contact emergency services with captured media
      await _contactEmergencyServices(emergencyContacts, emergencyEmail);

      // Setup periodic updates
      _sosTimer?.cancel();
      _sosTimer = Timer.periodic(Duration(minutes: 2), (_) {
        _contactEmergencyServices(emergencyContacts, emergencyEmail);
      });
    } catch (e) {
      print('Error during SOS activation: $e');
      // Still try to contact emergency services even if media capture fails
      await _contactEmergencyServices(emergencyContacts, emergencyEmail);
    }
  }

  Future<void> _contactEmergencyServices(
      List<String> contacts, String? email) async {
    if (_currentPosition == null) return;

    final message = '''EMERGENCY: I need help! 
Location: https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}
Time: ${DateTime.now().toString()}''';

    // Send SMS to all emergency contacts
    for (final contact in contacts) {
      await SmsService.sendSMS(contact, message);
    }

    // Send email with attachments if email is configured
    if (email != null) {
      final emailService = EmailService(
          'prathamesh9346@gmail.com', // Replace with your email
          'chdi auvd uqjo zrbo' // Replace with your app-specific password
          );

      try {
        await emailService.sendEmergencyEmail(
          recipientEmail: email,
          message: message,
          attachmentPaths: _capturedMedia,
        );
      } catch (e) {
        print('Error sending email: $e');
      }
    }
  }

  void deactivateSOS() {
    _sosTimer?.cancel();
    _cameraService.dispose();
    _audioService.dispose();
    _capturedMedia.clear();
  }

  void dispose() {
    deactivateSOS();
  }
}
