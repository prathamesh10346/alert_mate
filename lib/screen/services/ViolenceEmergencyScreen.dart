import 'package:alert_mate/widgets/emergency_Template.dart';
import 'package:flutter/material.dart';

class ViolenceEmergencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmergencyScreenTemplate(
      title: 'Violence Emergency',
      icon: Icons.security,
      emergencyNumber: '181',
      primaryColor: Colors.black,
      instructions: [
        'Get to a safe location immediately',
        'Lock doors and stay out of sight',
        'Silence your phone and stay quiet',
        'Call 911 when safe to do so',
        'Comply with all police instructions',
      ],
    );
  }
}