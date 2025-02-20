import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    primaryColor: const Color(0xFF2196F3),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF64B5F6),
      surface: Color(0xFF2C2C2C),
      background: Color(0xFF1A1A1A),
    ),
    cardColor: const Color(0xFF2C2C2C),
  );

  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF2196F3),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF64B5F6),
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
    ),
    cardColor: Colors.white,
  );
}
