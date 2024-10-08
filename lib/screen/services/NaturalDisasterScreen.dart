import 'package:alert_mate/widgets/emergency_Template.dart';
import 'package:flutter/material.dart';

class NaturalDisasterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmergencyScreenTemplate(
      title: 'Natural Disaster',
      icon: Icons.warning,
      emergencyNumber: '108',
      primaryColor: Colors.purple,
      instructions: [
        'Stay informed through official channels',
        'Follow evacuation orders if given',
        'Have an emergency kit ready',
        'Stay away from damaged buildings and downed power lines',
        'Help injured or trapped persons if safe to do so',
      ],
    );
  }
}