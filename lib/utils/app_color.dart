import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color.fromARGB(136, 255, 123, 0);
  static const Color secondaryColor = Color.fromARGB(255, 26, 26, 26);
  static const Color buttonColor = Color.fromARGB(151, 255, 123, 0);
  static const Color lightWhiteColor = Color(0xFFE0E0E0);
  static const Color appBarColor = Color(0xFF310048);
  static const Color boxColor = Color(0xFF49036A);
  static const Color textColor = Color(0xFFF025DC);
  static const Color text1Color = Color(0xFFDA2DDD);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
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
