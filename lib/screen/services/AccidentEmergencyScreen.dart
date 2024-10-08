import 'package:alert_mate/widgets/emergency_Template.dart';
import 'package:flutter/material.dart';

class AccidentEmergencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmergencyScreenTemplate(
      title: 'Accident Emergency',
      icon: Icons.car_crash,
      emergencyNumber: '112',
      primaryColor: Colors.blue,
      instructions: [
        'Ensure the scene is safe before approaching',
        'Check for injuries and call for medical help',
        'Do not move injured persons unless in immediate danger',
        'Turn off vehicle engines and do not smoke',
        'Use hazard lights or flares to warn other drivers',
      ],
    );
  }
}