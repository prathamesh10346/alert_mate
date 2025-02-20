// women_safety_screen.dart
import 'package:alert_mate/screen/devies_details/fake_call_screen.dart';
import 'package:alert_mate/services/audio_service.dart';
import 'package:alert_mate/services/camera_service.dart';
import 'package:alert_mate/services/email_service.dart';
import 'package:alert_mate/services/media_service.dart';
import 'package:alert_mate/services/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class WomenSafetyScreen extends StatefulWidget {
  @override
  _WomenSafetyScreenState createState() => _WomenSafetyScreenState();
}

class _WomenSafetyScreenState extends State<WomenSafetyScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> emergencyContacts = [];
  bool isSOSActive = false;
  Timer? _sosTimer;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  final AudioService _audioService = AudioService();
  final CameraService _cameraService = CameraService();
  Timer? _captureTimer;
  List<String> _capturedMedia = [];

  static const platform = MethodChannel('com.your.app/sms');
  static const platformCall = MethodChannel('com.your.app/phone_call');
  static const platformFakeCall = MethodChannel('com.your.app/fake_call');
  final MediaService _mediaService = MediaService();
  String? _emergencyEmail;
  final EmailService _emailService = EmailService(
      'prathamesh9346@gmail.com', // Replace with your email
      'chdi auvd uqjo zrbo' // Replace with your app-specific password
      );

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
    _initializeLocation();
    _requestPermissions();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
        _emergencyEmail = prefs.getString('emergency_email');
      });
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  // Add method to save emergency email
  Future<void> _saveEmergencyEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergency_email', email);
      setState(() {
        _emergencyEmail = email;
      });
    } catch (e) {
      print('Error saving email: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request all required permissions at startup
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
        Permission.camera,
        Permission.location,
      ].request();

      // Check if any permission was denied
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Some permissions were denied. SOS features may be limited.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _cameraService.initialize();
      await _audioService.initialize();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition();

      // Start location updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          setState(() => _currentPosition = position);
        },
        onError: (e) {
          print('Location stream error: $e');
        },
      );
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  Future<void> _addEmergencyEmail() async {
    final TextEditingController emailController =
        TextEditingController(text: _emergencyEmail);
    final formKey = GlobalKey<FormState>(); // Create a new form key here

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Use dialogContext instead
        title: Text('Set Emergency Email'),
        content: Form(
          key: formKey, // Use the local form key
          child: TextFormField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter an email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Use formKey instead of Form.of()
                await _saveEmergencyEmail(emailController.text);
                Navigator.pop(dialogContext);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEmergencyContacts(List<String> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('emergency_contacts', contacts);
      setState(() {
        emergencyContacts = contacts;
      });
    } catch (e) {
      print('Error saving contacts: $e');
    }
  }

  Future<void> _addEmergencyContact() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Emergency Contact'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Please enter a phone number';
                  // Basic phone number validation
                  if (!RegExp(r'^\+?[\d\s-]+$').hasMatch(value!)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final contact =
                    '${nameController.text}:${phoneController.text}';
                await _saveEmergencyContacts([...emergencyContacts, contact]);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateSOS() async {
    if (emergencyContacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add emergency contacts first')),
        );
      }
      return;
    }

    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Waiting for location data...')),
        );
      }
      return;
    }

    setState(() => isSOSActive = true);

    try {
      // Initialize camera service
      await _cameraService.initialize();

      // Start capturing photos every 2 seconds for 10 seconds
      _capturedMedia = await _cameraService.startPeriodicCapture();

      print('Total captured media: ${_capturedMedia.length}');

      // Contact emergency services with captured media
      await _contactEmergencyServices(_capturedMedia);

      // Clear captured media after sending
      _capturedMedia.clear();

      // Setup periodic updates
      _sosTimer?.cancel();
      _sosTimer = Timer.periodic(Duration(minutes: 2), (_) {
        _contactEmergencyServices(_capturedMedia);
      });

      // Try to call emergency contact if available
      if (emergencyContacts.isNotEmpty) {
        try {
          final contact = emergencyContacts[0];
          final parts = contact.split(':');
          if (parts.length >= 2) {
            final phoneNumber = parts[1].trim();
            if (phoneNumber.isNotEmpty) {
              await platformCall.invokeMethod('makePhoneCall', {
                'phoneNumber': phoneNumber,
              });
            }
          }
        } catch (e) {
          print('Error making emergency call: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to initiate emergency call')),
            );
          }
        }
      }
    } catch (e) {
      print('Error during SOS activation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error capturing photos. Emergency contacts will still be notified.')),
        );
      }
      // Still try to contact emergency services even if photo capture fails
      await _contactEmergencyServices([]);
    } finally {
      // Cleanup
      await _cameraService.dispose();
    }
  }

  Future<void> _contactEmergencyServices(List<String> mediaFiles) async {
    final message = '''EMERGENCY: I need help! 
Location: https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}
Time: ${DateTime.now().toString()}''';

    // Send SMS
    for (final contact in emergencyContacts) {
      await SmsService.sendSMS(contact, message);
    }
    print('mediaFiles: $mediaFiles\n' +
        'message: $message\n' +
        'emergencyContacts: ${emergencyContacts.join(', ')}');
    print("Sending the mail");

    // Send email with attachments
    if (_emergencyEmail != null) {
      try {
        await _emailService.sendEmergencyEmail(
          recipientEmail: _emergencyEmail!,
          message: message,
          attachmentPaths: mediaFiles,
        );

        print("Sent the mail");
      } catch (e) {
        print('Error sending email: $e');
      }
    }
  }

  Future<void> _simulateFakeCall() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FakeCallScreen(),
        ),
      );
    } catch (e) {
      print('Error initiating fake call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate fake call')),
        );
      }
    }
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _positionStream?.cancel();
    _captureTimer?.cancel();
    _cameraService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  // Build method and UI remain the same...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Women Safety'),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Emergency Contacts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    ...emergencyContacts.map((contact) {
                      final parts = contact.split(':');
                      return ListTile(
                        leading: Icon(Icons.person),
                        title: Text(parts.isNotEmpty ? parts[0] : 'Unknown'),
                        subtitle: Text(parts.length > 1 ? parts[1] : ''),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            final updatedContacts =
                                List<String>.from(emergencyContacts)
                                  ..remove(contact);
                            await _saveEmergencyContacts(updatedContacts);
                          },
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add Emergency Contact'),
                      onPressed: _addEmergencyContact,
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Emergency Email'),
                      subtitle: Text(_emergencyEmail ?? 'Not set'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: _addEmergencyEmail,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSOSActive ? null : _activateSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isSOSActive ? 'SOS Active' : 'Activate SOS',
                style: TextStyle(fontSize: 18),
              ),
            ),
            if (isSOSActive)
              ElevatedButton(
                onPressed: () {
                  setState(() => isSOSActive = false);
                  _sosTimer?.cancel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Stop SOS', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _simulateFakeCall,
        child: Icon(Icons.phone),
        backgroundColor: Colors.pink,
      ),
    );
  }
}
