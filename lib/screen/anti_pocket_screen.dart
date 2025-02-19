// anti_pocket_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AntiPocketScreen extends StatefulWidget {
  @override
  _AntiPocketScreenState createState() => _AntiPocketScreenState();
}

class _AntiPocketScreenState extends State<AntiPocketScreen> {
  bool isEnabled = false;
  bool isAlarming = false;
  String? alarmPassword;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  double threshold = 12.0;
  static const platform = MethodChannel('com.your.app/device_control');
  final TextEditingController _passwordController = TextEditingController();
  double accelerometerThreshold = 150.0; // Increased from 12.0
  double gyroscopeThreshold = 40.0; // Separate threshold for rotation
  DateTime? lastSignificantMotion;
  int motionCounter = 0;
  static const int requiredMotions = 3;
  static const Duration motionWindow = Duration(milliseconds: 5000);
  DateTime? lastAlarmStop;
  static const Duration cooldownPeriod = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      alarmPassword = prefs.getString('alarm_password');
    });
  }

  Future<void> _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_password', password);
    setState(() {
      alarmPassword = password;
    });
  }

  Future<void> _requestPermissions() async {
    // Add permissions if needed
  }

  void startMonitoring() {
    if (alarmPassword == null || alarmPassword!.isEmpty) {
      _showSetPasswordDialog();
      return;
    }

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double magnitude =
          (event.x * event.x + event.y * event.y + event.z * event.z).abs();

      // Remove gravity component (approximately 9.8 m/s²)
      magnitude = (magnitude - 9.8).abs();

      if (magnitude > accelerometerThreshold && isEnabled && !isAlarming) {
        print("Gravity The magnitude is $magnitude");
        _handleSignificantMotion();
      }
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      double rotation =
          (event.x * event.x + event.y * event.y + event.z * event.z).abs();

      if (rotation > gyroscopeThreshold && isEnabled && !isAlarming) {
        print("Gyroscope The magnitude is $rotation");
        _handleSignificantMotion();
      }
    });
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    motionCounter = 0;
    lastSignificantMotion = null;
    lastAlarmStop = null; // Reset cooldown when monitoring is stopped
    setState(() {
      isEnabled = false;
      isAlarming = false;
    });
  }

  void _handleSignificantMotion() {
    final now = DateTime.now();

    if (lastSignificantMotion == null ||
        now.difference(lastSignificantMotion!) > motionWindow) {
      // Reset counter if too much time has passed
      motionCounter = 1;
    } else {
      motionCounter++;
    }

    lastSignificantMotion = now;

    if (motionCounter >= requiredMotions) {
      triggerAlarm();
      motionCounter = 0;
    }
  }

  Future<void> triggerAlarm() async {
    // Check if alarm is already active
    if (isAlarming) return;

    // Check if we're in cooldown period
    if (lastAlarmStop != null) {
      final now = DateTime.now();
      if (now.difference(lastAlarmStop!) < cooldownPeriod) {
        return; // Still in cooldown, don't trigger
      }
    }

    setState(() {
      isAlarming = true;
    });

    try {
      await platform.invokeMethod('disableHardwareButtons');
      await platform.invokeMethod('startAlarm');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          String enteredPassword = '';

          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text('⚠️ Anti-Pocket Alert!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Suspicious movement detected!'),
                  SizedBox(height: 20),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Enter Password to Stop Alarm',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => enteredPassword = value,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Stop Alarm'),
                  onPressed: () async {
                    if (enteredPassword == alarmPassword) {
                      await platform.invokeMethod('enableHardwareButtons');
                      await platform.invokeMethod('stopAlarm');
                      setState(() {
                        isAlarming = false;
                        lastAlarmStop =
                            DateTime.now(); // Set cooldown timestamp
                        motionCounter = 0; // Reset motion counter
                      });
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Incorrect password!')),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('Error triggering alarm: $e');
    }
  }

  void _showSetPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Protection Password'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Enter Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                setState(() {
                  isEnabled = false;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                if (_passwordController.text.isNotEmpty) {
                  _savePassword(_passwordController.text);
                  Navigator.of(context).pop();
                  startMonitoring();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    stopMonitoring();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anti-Pocket Protection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEnabled ? Icons.security : Icons.security_outlined,
              size: 100,
              color: isEnabled ? Colors.green : Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              isEnabled ? 'Protection Active' : 'Protection Inactive',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  isEnabled = value;
                  if (value) {
                    startMonitoring();
                  } else {
                    stopMonitoring();
                  }
                });
              },
            ),
            TextButton(
              onPressed: () {
                _showSetPasswordDialog();
              },
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
