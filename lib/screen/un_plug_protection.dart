import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnplugProtectionScreen extends StatefulWidget {
  @override
  _UnplugProtectionScreenState createState() => _UnplugProtectionScreenState();
}

class _UnplugProtectionScreenState extends State<UnplugProtectionScreen> {
  bool isEnabled = false;
  bool isAlarming = false;
  String? alarmPassword;
  static const platform = MethodChannel('com.your.app/device_control');
  final TextEditingController _passwordController = TextEditingController();
  final Battery _battery = Battery();
  bool _isCharging = false;
  DateTime? lastAlarmStop;
  static const Duration cooldownPeriod = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadPassword();
    _initBatteryState();
  }

  Future<void> _initBatteryState() async {
    final batteryState = await _battery.batteryState;
    _updateChargingState(batteryState);
    
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _updateChargingState(state);
    });
  }

  void _updateChargingState(BatteryState state) {
    bool newChargingState = state == BatteryState.charging || 
                           state == BatteryState.full;
    
    if (_isCharging && !newChargingState && isEnabled && !isAlarming) {
      // Cable was unplugged while protection was active
      triggerAlarm();
    }
    
    setState(() {
      _isCharging = newChargingState;
    });
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
              title: Text('⚠️ Charger Unplugged Alert!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Charging cable has been disconnected!'),
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
                        isEnabled = false;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unplug Protection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCharging ? Icons.battery_charging_full : Icons.battery_alert,
              size: 100,
              color: isEnabled && _isCharging ? Colors.green : 
                     isEnabled && !_isCharging ? Colors.red : Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              _isCharging ? 'Charging' : 'Not Charging',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              isEnabled ? 'Protection Active' : 'Protection Inactive',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                if (!_isCharging && value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please connect charger first')),
                  );
                  return;
                }
                if (value && (alarmPassword == null || alarmPassword!.isEmpty)) {
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
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}