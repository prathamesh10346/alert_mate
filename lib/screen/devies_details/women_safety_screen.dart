// women_safety_screen.dart
import 'package:alert_mate/screen/dashboard/main_screen.dart';
import 'package:alert_mate/screen/devies_details/fake_call_screen.dart';
import 'package:alert_mate/screen/services/SOSService.dart';
import 'package:alert_mate/services/audio_service.dart';
import 'package:alert_mate/services/camera_service.dart';
import 'package:alert_mate/services/email_service.dart';
import 'package:alert_mate/services/media_service.dart';
import 'package:alert_mate/services/sms_service.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:animate_do/animate_do.dart';
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

class _WomenSafetyScreenState extends State<WomenSafetyScreen>
    with SingleTickerProviderStateMixin {
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
  final SOSService _sosService = SOSService();
  String _currentAddress = "Detecting location...";
  static const platform = MethodChannel('com.your.app/sms');
  static const platformCall = MethodChannel('com.your.app/phone_call');
  static const platformFakeCall = MethodChannel('com.your.app/fake_call');
  final MediaService _mediaService = MediaService();
  String? _emergencyEmail;
  final EmailService _emailService = EmailService(
      'prathamesh9346@gmail.com', // Replace with your email
      'chdi auvd uqjo zrbo' // Replace with your app-specific password
      );
  late AnimationController _sosAnimationController;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
    _initializeLocation();
    _requestPermissions();

    _sosAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
  }

  Future<void> _loadEmergencyContacts() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        emergencyContacts = prefs.getStringList('emergency_contacts') ?? [];
        _emergencyEmail = prefs.getString('emergency_email');
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() => _isLoading = false);
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
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          forceAndroidLocationManager: true);
      _currentAddress =
          "Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCE4EC),
              Color(0xFFF8BBD0),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateFakeCall,
        icon: Icon(Icons.phone_in_talk),
        label: Text("Fake Call"),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildTopBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.pinkAccent,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Location',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 3.5.w,
                      ),
                    ),
                    _isLoading
                        ? SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pinkAccent,
                            ),
                          )
                        : Text(
                            _currentAddress,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 3.8.w,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ],
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings,
                color: Colors.pinkAccent,
                size: 6.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Are you feeling unsafe?',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 7.w,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            FadeInRight(
              duration: const Duration(milliseconds: 700),
              child: Text(
                'Press the SOS button below for immediate help. Your location will be shared with your trusted contacts.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 4.w,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 5.h),
            _buildSOSButton(),
            SizedBox(height: 5.h),
            _buildContactsCard(),
            SizedBox(height: 4.h),
            _buildEmergencyOptions(),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOptions() {
    List<Map<String, dynamic>> options = [
      {
        'icon': Icons.local_police_outlined,
        'label': 'Police',
        'color': Color(0xFF3F51B5),
      },
      {
        'icon': Icons.local_hospital_outlined,
        'label': 'Medical',
        'color': Color(0xFFE53935),
      },
      {
        'icon': Icons.phone_in_talk_outlined,
        'label': 'Helpline',
        'color': Color(0xFF8BC34A),
      },
      {
        'icon': Icons.directions_run,
        'label': 'Escape',
        'color': Color(0xFFFF9800),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 5.w,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 4.w,
            mainAxisSpacing: 2.h,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            return FadeInUp(
              duration: Duration(milliseconds: 600 + (index * 100)),
              child: GestureDetector(
                onTap: () {
                  // Navigate to appropriate action screen
                },
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        options[index]['color'].withOpacity(0.8),
                        options[index]['color'],
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: options[index]['color'].withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          options[index]['icon'],
                          color: Colors.white,
                          size: 8.w,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        options[index]['label'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 4.w,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactsCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trusted Contacts',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 5.w,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: GestureDetector(
                    onTap: _addEmergencyContact,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.pinkAccent,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 3.5.w,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            emergencyContacts.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/add_contact.png',
                          height: 15.h,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Add trusted contacts who will be notified in emergencies',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 3.5.w,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: emergencyContacts.length,
                    separatorBuilder: (context, index) => Divider(height: 2.h),
                    itemBuilder: (context, index) {
                      final parts = emergencyContacts[index].split(':');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.pink.withOpacity(0.1),
                          child: Text(
                            parts[0][0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          parts.isNotEmpty ? parts[0] : 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 4.w,
                          ),
                        ),
                        subtitle: Text(
                          parts.length > 1 ? parts[1] : '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 3.5.w,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.grey[400],
                          ),
                          onPressed: () async {
                            final updatedContacts =
                                List<String>.from(emergencyContacts)
                                  ..remove(emergencyContacts[index]);
                            await _saveEmergencyContacts(updatedContacts);
                          },
                        ),
                      );
                    },
                  ),
            SizedBox(height: 2.h),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: Colors.pinkAccent,
                ),
              ),
              title: Text(
                'Emergency Email',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 4.w,
                ),
              ),
              subtitle: Text(
                _emergencyEmail ?? 'Not set',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 3.5.w,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.pinkAccent,
                ),
                onPressed: _addEmergencyEmail,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          try {
            setState(() {
              isSOSActive = !isSOSActive;
            });

            if (isSOSActive) {
              // Start animations
              _sosAnimationController.repeat(reverse: true);

              // Haptic feedback
              HapticFeedback.heavyImpact();

              // Check for emergency contacts
              if (emergencyContacts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please add emergency contacts first'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                setState(() => isSOSActive = false);
                _sosAnimationController.reset();
                return;
              }

              // Activate SOS

              await _activateSOS();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('SOS activated! Help is on the way.'),
                  backgroundColor: Colors.pinkAccent,
                ),
              );
            } else {
              // Deactivate SOS
              _sosAnimationController.reset();
              _sosAnimationController.stop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('SOS deactivated'),
                  backgroundColor: Colors.grey,
                ),
              );
            }
          } catch (e) {
            print('Error in SOS activation: $e');
            setState(() => isSOSActive = false);
            _sosAnimationController.reset();
          }
        },
        child: AnimatedBuilder(
          animation: _sosAnimationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Multiple ripple effects for active state
                if (isSOSActive)
                  ...List.generate(3, (index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(seconds: 2),
                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: (1.0 - value) * 0.7,
                          child: Transform.scale(
                            scale: 0.5 + (value * 0.8) + (index * 0.2),
                            child: Container(
                              width: 45.w,
                              height: 45.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(
                                  Colors.redAccent,
                                  Colors.red.shade800,
                                  _sosAnimationController.value,
                                )!
                                    .withOpacity(0.3 - (index * 0.1)),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                // Main SOS button with pulse effect
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: isSOSActive ? 0.9 : 1.0,
                    end: isSOSActive ? 1.1 : 1.0,
                  ),
                  duration: Duration(milliseconds: isSOSActive ? 800 : 300),
                  curve: isSOSActive ? Curves.easeInOut : Curves.bounceOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: isSOSActive
                          ? scale * (0.95 + _sosAnimationController.value * 0.1)
                          : scale,
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSOSActive
                                ? [Colors.red.shade600, Colors.redAccent]
                                : [Colors.pinkAccent, Colors.pink.shade300],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSOSActive
                                  ? Colors.red.withOpacity(
                                      0.5 + _sosAnimationController.value * 0.3)
                                  : Colors.pinkAccent.withOpacity(0.3),
                              blurRadius: isSOSActive
                                  ? 25 + (_sosAnimationController.value * 15)
                                  : 20,
                              spreadRadius: isSOSActive ? 4 : 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isSOSActive
                                  ? FadeIn(
                                      child: ShakeAnimatedWidget(
                                        enabled: isSOSActive,
                                        duration: Duration(milliseconds: 1000),
                                        shakeAngle: Rotation.deg(z: 1),
                                        curve: Curves.elasticOut,
                                        child: Text(
                                          'SOS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.w,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 3,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.w,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                              SizedBox(height: 1.h),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  isSOSActive ? 'ACTIVE' : 'Press for Help',
                                  key: ValueKey(isSOSActive),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 3.5.w,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
