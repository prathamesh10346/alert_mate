import 'dart:async';

import 'package:alert_mate/services/phone_service.dart';
import 'package:alert_mate/services/sms_service.dart';
import 'package:flutter/material.dart';
import '../services/accident_detection_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccidentDetectionScreen extends StatefulWidget {
  @override
  _AccidentDetectionScreenState createState() =>
      _AccidentDetectionScreenState();
}

class _AccidentDetectionScreenState extends State<AccidentDetectionScreen> {
  late AccidentDetectionService _accidentService;
  bool _isMonitoring = false;
  List<String> _emergencyContacts = [];
  AccidentData? _lastAccidentData;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadEmergencyContacts();
  }

  Future<void> _initializeService() async {
    _accidentService = AccidentDetectionService(
      onAccidentDetected: _handleAccidentDetection,
    );
  }

  Future<void> _loadEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
    });
  }

  Future<void> _addEmergencyContact() async {
    final TextEditingController controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                helperText: 'Format: +CountryCode PhoneNumber',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                if (_isValidPhoneNumber(controller.text)) {
                  final prefs = await SharedPreferences.getInstance();
                  final contacts = [..._emergencyContacts, controller.text];
                  await prefs.setStringList('emergency_contacts', contacts);
                  setState(() {
                    _emergencyContacts = contacts;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please enter a valid phone number')),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  bool _isDialogShowing = false;
  Timer? _emergencyTimer;
  void _handleAccidentDetection(AccidentData accidentData) async {
    if (_isDialogShowing) return; // Prevent multiple dialogs

    setState(() {
      _lastAccidentData = accidentData;
      _isDialogShowing = true;
    });

    // Cancel any existing emergency timer
    _emergencyTimer?.cancel();

    // Show alert dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _emergencyTimer = Timer(Duration(seconds: 30), () {
          Navigator.of(context).pop(); // Close dialog
          _contactEmergencyServices(accidentData);
        });

        return AlertDialog(
          title: Text('Accident Detected!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Are you okay? Emergency services will be contacted in 30 seconds if no response.'),
              SizedBox(height: 10),
              Text('Reason: ${accidentData.reason}'),
              Text(
                  'Impact Force: ${accidentData.acceleration.toStringAsFixed(2)} m/s²'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _emergencyTimer?.cancel();
                _isDialogShowing = false;
                Navigator.pop(context);
              },
              child: Text('I\'m OK'),
            ),
            TextButton(
              onPressed: () {
                _emergencyTimer?.cancel();
                Navigator.pop(context);
                _contactEmergencyServices(accidentData);
              },
              child: Text('Get Help Now'),
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogShowing = false;
      _emergencyTimer?.cancel();
    });
  }

  Future<void> _contactEmergencyServices(AccidentData accidentData) async {
    // Prepare emergency message
    final message = 'Emergency! Accident detected at '
        'https://www.google.com/maps?q=${accidentData.location.latitude},'
        '${accidentData.location.longitude}\n'
        'Impact Force: ${accidentData.acceleration.toStringAsFixed(2)} m/s²\n'
        'Speed: ${accidentData.speed.toStringAsFixed(2)} m/s';

    bool emergencyCallMade = false;

    // First try emergency contacts
    for (final contact in _emergencyContacts) {
      if (!emergencyCallMade) {
        try {
          // Send SMS first (don't wait for it to complete)
          SmsService.sendSMS(contact, message).then((success) {
            if (!success) {
              print('Failed to send SMS to $contact');
            }
          });
          await SmsService.sendEmergencySMS(_emergencyContacts, message);
          // Make direct call
          emergencyCallMade = await PhoneService.makePhoneCall(contact);

          if (emergencyCallMade) break; // Exit after successful call
        } catch (e) {
          print('Error contacting $contact: $e');
        }
      }
    }

    // If no emergency contacts were reached, call emergency services
    if (!emergencyCallMade) {
      try {
        emergencyCallMade = await PhoneService.makePhoneCall('112');
        if (!emergencyCallMade) {
          // Fallback to url_launcher if direct call fails
          final emergencyUri = Uri.parse('tel:112');
          await launchUrl(emergencyUri);
        }
      } catch (e) {
        print('Error calling emergency services: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to contact emergency services')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accident Detection'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Accident Detection Status',
                  
                    ),
                    Switch(
                      value: _isMonitoring,
                      onChanged: (value) {
                        setState(() {
                          _isMonitoring = value;
                        });
                        if (value) {
                          _accidentService.startMonitoring(context);
                        } else {
                          _accidentService.dispose();
                        }
                      },
                    ),
                    Text(_isMonitoring
                        ? 'Monitoring Active'
                        : 'Monitoring Inactive'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contacts',
       
                    ),
                    SizedBox(height: 8),
                    ..._emergencyContacts.map((contact) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(contact),
                        )),
                    TextButton(
                      onPressed: _addEmergencyContact,
                      child: Text('Add Emergency Contact'),
                    ),
                  ],
                ),
              ),
            ),
            if (_lastAccidentData != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Detected Accident',
              
                      ),
                      SizedBox(height: 8),
                      Text('Time: ${_lastAccidentData!.timestamp}'),
                      Text('Reason: ${_lastAccidentData!.reason}'),
                      Text(
                          'Force: ${_lastAccidentData!.acceleration.toStringAsFixed(2)} m/s²'),
                      Text(
                          'Speed: ${_lastAccidentData!.speed.toStringAsFixed(2)} m/s'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isValidPhoneNumber(String phone) {
    // Basic phone number validation
    final phoneRegExp = RegExp(r'^\+?[\d\s-]{8,}$');
    return phoneRegExp.hasMatch(phone);
  }

  @override
  void dispose() {
    _emergencyTimer?.cancel();
    _accidentService.dispose();
    super.dispose();
  }
}
