import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF64B5F6);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color accentColor = Color(0xFFFF7A00);
  static const Color dangerColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);


  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color blue = Colors.blue;

  static RadialGradient get radialGradient {
    return RadialGradient(
      colors: [
        primaryColor,
        secondaryColor,
      ],
      stops: [0.0, 0.5],
      center: Alignment.center,
      radius: 1.5,
    );
  }

  static LinearGradient getDarkGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
    );
  }

  static LinearGradient getLightGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF5F5F5), Colors.white],
    );
  }

  static LinearGradient getAccentGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
    );
  }

  static LinearGradient getDangerGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE53935), Color(0xFFEF5350)],
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(10));

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xffFF7A00), Color.fromARGB(255, 254, 255, 255)],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
