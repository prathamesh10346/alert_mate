// theft_mode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TheftModeScreen extends StatefulWidget {
  @override
  _TheftModeScreenState createState() => _TheftModeScreenState();
}

class _TheftModeScreenState extends State<TheftModeScreen> {
  bool isTheftModeEnabled = false;
  static const platform = MethodChannel('com.your.app/theft_mode');

  Future<void> toggleTheftMode(bool value) async {
    try {
      await platform.invokeMethod('toggleTheftMode', {'enabled': value});
      setState(() {
        isTheftModeEnabled = value;
      });
    } on PlatformException catch (e) {
      print("Failed to toggle theft mode: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theft Mode'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 48,
                      color: isTheftModeEnabled ? Colors.green : Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Theft Mode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When enabled, your device will be locked and can only be unlocked through the web panel.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Switch(
                      value: isTheftModeEnabled,
                      onChanged: toggleTheftMode,
                    ),
                  ],
                ),
              ),
            ),
            if (isTheftModeEnabled)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Device is currently locked.\nUse web panel to unlock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}