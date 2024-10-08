import 'package:alert_mate/widgets/emergency_Template.dart';
import 'package:flutter/material.dart';

class FireEmergencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmergencyScreenTemplate(
      title: 'Fire Emergency',
      icon: Icons.local_fire_department,
      emergencyNumber: '101',
      primaryColor: Colors.orange,
      instructions: [
        'Evacuate the building immediately',
        'Close doors behind you to contain the fire',
        'Use stairs, never elevators',
        'If trapped, seal doors and vents with wet cloths',
        'Signal for help from a window if possible',
      ],
    );
  }
}