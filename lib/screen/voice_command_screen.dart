import 'package:alert_mate/services/voice_command_handler.dart';
import 'package:flutter/material.dart';

class VoiceCommandScreen extends StatefulWidget {
  @override
  _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final VoiceCommandHandler _voiceCommandHandler = VoiceCommandHandler();
  String _detectedCommand = "No command detected.";

  void _handleCommand(String command) {
    setState(() {
      _detectedCommand = command;
    });

    if (command.contains("help") || command.contains("sos")) {
      _triggerSOS();
    } else if (command.contains("alert")) {
      _triggerAlert();
    }
  }

  void _triggerSOS() {
    print("SOS Triggered!");
    // Add logic to send SOS alerts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("SOS triggered!")),
    );
  }

  void _triggerAlert() {
    print("Alert Triggered!");
    // Add logic for other alerts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Alert triggered!")),
    );
  }

  @override
  void dispose() {
    _voiceCommandHandler.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Commands"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Detected Command:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _detectedCommand,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _voiceCommandHandler.startListening(_handleCommand);
              },
              child: Text("Start Listening"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _voiceCommandHandler.stopListening();
                setState(() {
                  _detectedCommand = "No command detected.";
                });
              },
              child: Text("Stop Listening"),
            ),
          ],
        ),
      ),
    );
  }
}
