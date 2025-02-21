import 'package:alert_mate/providers/contacts_provider.dart';
import 'package:alert_mate/providers/emergency_service.dart';
import 'package:alert_mate/providers/medical_facilities_provider.dart';
import 'package:alert_mate/providers/theme_provider.dart';
import 'package:alert_mate/screen/Splash_screen/splash_screen.dart';
import 'package:alert_mate/screen/dashboard/main_screen.dart';
import 'package:alert_mate/services/accident_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e");
  }

  // Removed the call to initializeAllPlugins as it does not exist
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              MedicalFacilitiesProvider(dotenv.env['GOOGLE_MAPS_API_KEY']!),
        ),
        ChangeNotifierProvider(
          create: (_) => EmergencyServicesProvider(
              dotenv.env['GOOGLE_MAPS_API_KEY']!, 'police'),
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
