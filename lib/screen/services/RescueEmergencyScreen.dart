import 'package:alert_mate/widgets/emergency_Template.dart';
import 'package:flutter/material.dart';

class RescueEmergencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmergencyScreenTemplate(
      title: 'Rescue Emergency',
      icon: Icons.health_and_safety,
      emergencyNumber: '112',
      primaryColor: Colors.green,
      instructions: [
        'Do not put yourself in danger',
        'Call for professional help immediately',
        'If safe, try to reach out to the person in distress',
        'Provide clear location details to rescuers',
        'Follow instructions given by emergency services',
      ],
    );
  }
}
