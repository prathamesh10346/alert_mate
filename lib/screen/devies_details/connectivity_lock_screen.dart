import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:airplane_mode_checker/airplane_mode_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AirplaneModeMonitor extends StatefulWidget {
  @override
  _AirplaneModeMonitorState createState() => _AirplaneModeMonitorState();
}

class _AirplaneModeMonitorState extends State<AirplaneModeMonitor> {
  bool isMonitoringEnabled = false;
  Stream<AirplaneModeStatus>? _airplaneModeStream;
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupMonitoring();
  }

  void _setupMonitoring() {
    _airplaneModeStream = AirplaneModeChecker.instance.listenAirplaneMode();
    _airplaneModeStream?.listen((status) async {
      if (status == AirplaneModeStatus.on && isMonitoringEnabled) {
        await _disableAirplaneMode();
        _showNotification('Airplane mode was automatically disabled');
      }
    });
  }

  Future<void> _disableAirplaneMode() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        await MethodChannel('com.example.airplane_mode_checker')
            .invokeMethod('disableAirplaneMode');
      } else {
        _showNotification('Please disable airplane mode manually on iOS');
      }
    } catch (e) {
      print('Error disabling airplane mode: $e');
      _showNotification('Unable to disable airplane mode automatically');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMonitoringEnabled = prefs.getBool('monitoring_enabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('monitoring_enabled', isMonitoringEnabled);
  }

  void _showNotification(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Airplane Mode Controller'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Auto-Disable Airplane Mode'),
              subtitle:
                  Text('Automatically turn off airplane mode when enabled'),
              value: isMonitoringEnabled,
              onChanged: (value) async {
                setState(() {
                  isMonitoringEnabled = value;
                });
                await _saveSettings();
                _showNotification(
                    value ? 'Auto-disable enabled' : 'Auto-disable disabled');
              },
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Current Status:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            StreamBuilder<AirplaneModeStatus>(
              stream: _airplaneModeStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Error monitoring airplane mode',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }

                final isEnabled = snapshot.data == AirplaneModeStatus.on;
                return ListTile(
                  leading: Icon(
                    isEnabled
                        ? Icons.airplanemode_active
                        : Icons.airplanemode_inactive,
                    color: isEnabled ? Colors.red : Colors.green,
                    size: 32,
                  ),
                  title: Text(
                    isEnabled ? 'Airplane Mode is ON' : 'Airplane Mode is OFF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.red : Colors.green,
                    ),
                  ),
                  subtitle: Text(isEnabled
                      ? 'Attempting to disable...'
                      : 'Normal connectivity mode'),
                );
              },
            ),
            if (isMonitoringEnabled) ...[
              Divider(),
              Padding(
                padding: EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Disable Active',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        Text(
                          Theme.of(context).platform == TargetPlatform.android
                              ? 'Airplane mode will be automatically disabled when enabled.'
                              : 'On iOS, you will be notified to disable airplane mode manually.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
