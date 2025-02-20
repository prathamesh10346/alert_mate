import 'package:alert_mate/providers/contacts_provider.dart';
import 'package:alert_mate/providers/emergency_service.dart';
import 'package:alert_mate/providers/medical_facilities_provider.dart';
import 'package:alert_mate/providers/theme_provider.dart';
import 'package:alert_mate/screen/Splash_screen/splash_screen.dart';
import 'package:alert_mate/screen/dashboard/main_screen.dart';
import 'package:alert_mate/services/accident_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => MedicalFacilitiesProvider(
                "AIzaSyCh05PaJJGDZFiqL_hsSi0KcCkw4W6rBI0")),
        ChangeNotifierProvider(
          create: (_) => EmergencyServicesProvider(
              'AIzaSyCh05PaJJGDZFiqL_hsSi0KcCkw4W6rBI0', 'police'),
        ),
        // ChangeNotifierProvider(
        //   create: (_) => EmergencyServicesProvider(
        //       'AIzaSyCh05PaJJGDZFiqL_hsSi0KcCkw4W6rBI0', 'fire_station'),
        // ),
        ChangeNotifierProvider(create: (_) => AccidentDetectionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
      ],
      child: MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
