import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoNotTouchScreen extends StatefulWidget {
  @override
  _DoNotTouchScreenState createState() => _DoNotTouchScreenState();
}

class _DoNotTouchScreenState extends State<DoNotTouchScreen> {
  bool isEnabled = false;
  bool isAlarming = false;
  String? alarmPassword;
  static const platform = MethodChannel('com.your.app/device_control');
  final TextEditingController _passwordController = TextEditingController();
  DateTime? lastAlarmStop;
  static const Duration cooldownPeriod = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
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

  Future<void> triggerAlarm() async {
    if (isAlarming) return;

    if (lastAlarmStop != null) {
      final now = DateTime.now();
      if (now.difference(lastAlarmStop!) < cooldownPeriod) {
        return;
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
              title: Text('⚠️ Do Not Touch Alert!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Screen touch detected!'),
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
                        lastAlarmStop = DateTime.now();
                        isEnabled = false; // Disable protection after alarm
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
                  setState(() {
                    isEnabled = true;
                  });
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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Do Not Touch Protection'),
      ),
      body: GestureDetector(
        onTapDown: (details) {
          if (isEnabled && !isAlarming) {
            triggerAlarm();
          }
        },
        onPanStart: (details) {
          if (isEnabled && !isAlarming) {
            triggerAlarm();
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEnabled ? Icons.do_not_touch : Icons.touch_app,
                  size: 100,
                  color: isEnabled ? Colors.red : Colors.grey,
                ),
                SizedBox(height: 20),
                Text(
                  isEnabled
                      ? 'Touch Protection Active'
                      : 'Touch Protection Inactive',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),
                Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    if (value &&
                        (alarmPassword == null || alarmPassword!.isEmpty)) {
                      _showSetPasswordDialog();
                    } else {
                      setState(() {
                        isEnabled = value;
                      });
                    }
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
        ),
      ),
    );
  }
}
