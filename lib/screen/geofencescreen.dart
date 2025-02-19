import 'package:alert_mate/screen/geofencing_screen.dart';
import 'package:flutter/material.dart';

class GeofenceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo-Fencing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GeofencingScreen(),
    );
  }
}

class GeoFence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;

  GeoFence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
}

class GeoFenceStatus {
  final String fenceId;
  final String name;
  final bool isInside;
  final DateTime timestamp;

  GeoFenceStatus({
    required this.fenceId,
    required this.name,
    required this.isInside,
    required this.timestamp,
  });
}
