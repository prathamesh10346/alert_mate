import 'dart:async';

import 'package:alert_mate/models/contact.dart';
import 'package:alert_mate/providers/contacts_provider.dart';
import 'package:alert_mate/providers/theme_provider.dart';
import 'package:alert_mate/screen/dashboard/mycircle/add_contact_screen.dart';
import 'package:alert_mate/services/phone_service.dart';
import 'package:alert_mate/services/sms_service.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:alert_mate/widgets/circular_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/accident_detection_service.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AccidentDetectionScreen extends StatefulWidget {
  @override
  _AccidentDetectionScreenState createState() =>
      _AccidentDetectionScreenState();
}

class _AccidentDetectionScreenState extends State<AccidentDetectionScreen> {
  late AccidentDetectionService _accidentService;
  bool _isMonitoring = false;
  AccidentData? _lastAccidentData;
  bool _isDialogShowing = false;
  Timer? _emergencyTimer;
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  late AccidentDetectionProvider _accidentProvider;
  late Position _currentLocation;
  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _initializeLocation();
    _initializeService();
    _accidentProvider =
        Provider.of<AccidentDetectionProvider>(context, listen: false);
    _getCurrentLocation();
    // Load contacts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContactsProvider>(context, listen: false).loadContacts();
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = position;
    });
  }

  Future<void> _initializeLocation() async {
    final position = await Geolocator.getCurrentPosition();
    Provider.of<AccidentDetectionProvider>(context, listen: false)
        .updateCurrentLocation(position);
  }

  Future<void> _initializeService() async {
    _accidentService = AccidentDetectionService(
      onAccidentDetected: _handleAccidentDetection,
    );
  }

  void _handleAccidentDetection(AccidentData accidentData) async {
    if (_isDialogShowing) return; // Prevent multiple dialogs

    setState(() {
      _lastAccidentData = accidentData;
      _isDialogShowing = true;
    });

    // Cancel any existing emergency timer
    _emergencyTimer?.cancel();

    final contacts =
        Provider.of<ContactsProvider>(context, listen: false).contacts;

    // Show alert dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Animation controller setup
        final dialogController = AnimationController(
          duration: const Duration(seconds: 30),
          vsync: Navigator.of(context),
        );
        final animation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(dialogController);
        dialogController.forward();

        // Set up TTS
        var ttsCount = 0;
        Timer(const Duration(seconds: 10), () async {
          if (ttsCount < 1) {
            await flutterTts.setLanguage("en-US");
            await speakAndListen(
                "Are you okay? Respond with yes or no", accidentData);
            ttsCount++;
            Timer(const Duration(seconds: 3), () async {
              if (ttsCount < 1) {
                await speakAndListen(
                    "Are you okay? Respond with yes or no", accidentData);
                ttsCount++;
              }
            });
          }
        });

        // Initialize speech recognition
        requestMicrophonePermission().then((granted) {
          if (granted) {
            checkSpeechRecognitionAvailability();
          } else {
            print('Microphone permission denied');
          }
        });

        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(400, 400),
                  painter: CircularTimerPainter(
                    progress: animation.value,
                    backgroundColor: Colors.grey[800]!,
                    progressColor: Colors.red,
                  ),
                );
              },
            ),
            AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Accident Detected!',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you okay? Emergency services will be contacted in 30 seconds if no response.',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    stopListening();
                    Navigator.pop(context);
                  },
                  child: Text('I\'m OK'),
                ),
                TextButton(
                  onPressed: () {
                    stopListening();
                    Navigator.pop(context);
                    _contactEmergencyServices(accidentData, contacts);
                  },
                  child: Text(
                    'Get Help Now',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogShowing = false;
      _emergencyTimer?.cancel();
    });
  }

  Future<bool> requestMicrophonePermission() async {
    var permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      var result = await Permission.microphone.request();
      return result.isGranted;
    } else {
      return true;
    }
  }

  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText speech;
  bool isListening = false;
  String lastWords = '';
  void checkSpeechRecognitionAvailability() async {
    bool available = await speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );
    if (available) {
      print('Speech recognition available');
    } else {
      print('Speech recognition not available');
    }
  }

  void startListening(AccidentData accidentData, List<Contact> contacts) {
    print("Listening....");

    if (!isListening) {
      lastWords = '';
      speech.listen(
        onResult: (result) {
          setState(() {
            lastWords = result.recognizedWords;
            print('Recognized words: $lastWords');
            if (lastWords.toLowerCase().contains('yes')) {
              stopListening();
              Navigator.pop(context);
            } else if (lastWords.toLowerCase().contains('no')) {
              stopListening();
              _contactEmergencyServices(accidentData, contacts);
              Navigator.pop(context);
            }
          });
        },
        listenFor: const Duration(seconds: 20), // Set to listen for 20 seconds
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
        cancelOnError: true,
      );
      setState(() => isListening = true);
    }
  }

  void stopListening() {
    if (isListening) {
      speech.stop();
      setState(() => isListening = false);
    }
  }

  Future<void> speakAndListen(String text, AccidentData accidentData) async {
    await flutterTts.setLanguage("en-US");

    // Set up the completion handler to start listening after TTS completes
    flutterTts.setCompletionHandler(() {
      startListening(
        accidentData,
        Provider.of<ContactsProvider>(context, listen: false).contacts,
      );
    });

    // Speak the text
    await flutterTts.speak(text);
  }

  Future<void> _contactEmergencyServices(
      AccidentData accidentData, List<Contact> contacts) async {
    // Prepare emergency message
    final message = 'Emergency! Accident detected at '
        'https://www.google.com/maps?q=${accidentData.location.latitude},'
        '${accidentData.location.longitude}\n'
        'Impact Force: ${accidentData.acceleration.toStringAsFixed(2)} m/s²\n'
        'Speed: ${accidentData.speed.toStringAsFixed(2)} m/s';

    bool emergencyCallMade = false;

    // First try emergency contacts
    for (final contact in contacts) {
      if (!emergencyCallMade) {
        try {
          // Send SMS first (don't wait for it to complete)
          SmsService.sendSMS(contact.phoneNumber, message).then((success) {
            if (!success) {
              print('Failed to send SMS to ${contact.phoneNumber}');
            }
          });

          // Make direct call
          emergencyCallMade =
              await PhoneService.makePhoneCall(contact.phoneNumber);

          if (emergencyCallMade) break; // Exit after successful call
        } catch (e) {
          print('Error contacting ${contact.phoneNumber}: $e');
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
    SizeConfig().init(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Consumer<AccidentDetectionProvider>(
      builder: (context, provider, child) {
        return Theme(
          data: themeProvider.currentTheme,
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(height: 10),
                _buildTopBar(context),
                Expanded(
                  flex: 2,
                  child: _buildMap(provider),
                ),
                Expanded(
                  flex: 1,
                  child: _buildControls(context, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap(AccidentDetectionProvider provider) {
    if (provider.currentLocation == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              provider.currentLocation!.latitude,
              provider.currentLocation!.longitude,
            ),
            zoom: 15,
          ),
          markers: provider.accidentHotspots,
          polylines: Set<Polyline>.of(provider.polylines.values),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(top: 400, right: 0, left: 0, child: _buildHotspotsList()),
      ],
    );
  }

  Container _buildControls(
      BuildContext context, AccidentDetectionProvider provider) {
    return Container(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.h),
                      _buildStatusSection(provider),
                      SizedBox(height: 3.h),
                      _buildEmergencyContactsSection(),
                      if (_lastAccidentData != null) ...[
                        SizedBox(height: 3.h),
                        _buildLastAccidentSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 2.w),
          Text(
            'Accident Detection',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 5.w,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(AccidentDetectionProvider provider) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Status',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 4.5.w,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isMonitoring ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: provider.isMonitoring ? Colors.green : Colors.red,
                      fontSize: 4.w,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Detection Service',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 3.5.w,
                    ),
                  ),
                ],
              ),
              Switch(
                value: provider.isMonitoring,
                onChanged: (value) {
                  provider.toggleMonitoring(value);
                  setState(() {
                    _isMonitoring = value;
                  });
                  if (value) {
                    _accidentService.startMonitoring(context);
                  } else {
                    _accidentService.dispose();
                  }
                },
                activeColor: AppColors.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotsList() {
    if (_currentLocation == null) {
      return Center(child: CircularProgressIndicator());
    }

    final hotspots = _accidentProvider.accidentHotspots.where((marker) {
      final distance = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );
      return distance <= 10000; // 10 km
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: hotspots.length,
      itemBuilder: (context, index) {
        final hotspot = hotspots[index];
        final distance = Geolocator.distanceBetween(
          _currentLocation.latitude,
          _currentLocation.longitude,
          hotspot.position.latitude,
          hotspot.position.longitude,
        );
        final opacity =
            1.0 - (distance / 10000); // Fade effect based on distance

        return Opacity(
          opacity:
              opacity.clamp(0.3, 1.0), // Ensure opacity is between 0.3 and 1.0
          child: ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text(
              hotspot.infoWindow.title ?? '',
              style: TextStyle(
                color: AppColors.black.withOpacity(0.7),
              ),
            ),
            subtitle: Text(hotspot.infoWindow.snippet ?? '',
                style: TextStyle(
                  color: AppColors.black.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            onTap: () async {
              await _mapController?.animateCamera(
                CameraUpdate.newLatLng(hotspot.position),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Consumer<ContactsProvider>(
      builder: (context, contactsProvider, child) {
        final contacts = contactsProvider.contacts;

        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 4.5.w,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmergencyContactScreen(),
                      ),
                    ),
                    child: Text(
                      '+ Add',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 3.5.w,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              if (contacts.isEmpty)
                Center(
                  child: Text(
                    'No emergency contacts added yet',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 3.5.w,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                contact.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 5.w,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 4.w,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  contact.phoneNumber,
                                  style: TextStyle(
                                    color: AppColors.white.withOpacity(0.7),
                                    fontSize: 3.5.w,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteContact(contact.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLastAccidentSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Detected Accident',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 4.5.w,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow('Time', _lastAccidentData!.timestamp.toString()),
          _buildInfoRow('Reason', _lastAccidentData!.reason),
          _buildInfoRow('Force',
              '${_lastAccidentData!.acceleration.toStringAsFixed(2)} m/s²'),
          _buildInfoRow(
              'Speed', '${_lastAccidentData!.speed.toStringAsFixed(2)} m/s'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.7),
              fontSize: 3.5.w,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 3.5.w,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteContact(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete Contact',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Are you sure you want to delete this contact?',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ContactsProvider>(context, listen: false)
                  .deleteContact(id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emergencyTimer?.cancel();
    _accidentService.dispose();
    super.dispose();
  }
}
