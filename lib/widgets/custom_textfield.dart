import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  CustomTextField({
    required this.label,
    this.obscureText = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      
      decoration: InputDecoration(labelText: label),
      obscureText: obscureText,
      onChanged: onChanged,
    );
  }
}
