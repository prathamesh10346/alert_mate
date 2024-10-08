import 'package:alert_mate/widgets/emergency_Template.dart';
import 'package:flutter/material.dart';

class MedicalEmergencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmergencyScreenTemplate(
      title: 'Medical Emergency',
      icon: Icons.local_hospital,
      emergencyNumber: '102',
      primaryColor: Colors.red,
      instructions: [
        'Check for breathing and pulse',
        'If not breathing, start CPR immediately',
        'Control any bleeding by applying direct pressure',
        'Keep the person still and comfortable',
        'Treat for shock by keeping the person warm',
      ],
    );
  }
}