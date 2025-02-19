import 'dart:async';
import 'package:alert_mate/screen/geofencescreen.dart';
import 'package:alert_mate/services/Geolocation_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import 'notification_service.dart';

class GeofencingService {
  static final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();

  static List<GeoFence> geofences = [
    GeoFence(
      id: '1',
      name: 'Home Zone',
      latitude: 18.84995,
      longitude: 73.58298,
      radius: 500,
    ),
  ];
  Stream<GeoFenceStatus> monitorGeofences() async* {
    while (true) {
      try {
        Position currentPosition = await _locationService.getCurrentLocation();

        for (var fence in geofences) {
          double distance = Geolocator.distanceBetween(currentPosition.latitude,
              currentPosition.longitude, fence.latitude, fence.longitude);

          bool isInside = distance <= fence.radius;

          var status = GeoFenceStatus(
              fenceId: fence.id,
              name: fence.name,
              isInside: isInside,
              timestamp: DateTime.now());

          _handleGeofenceNotification(status);
          yield status;
        }
      } catch (e) {
        print('Geofencing error: $e');
      }

      await Future.delayed(Duration(minutes: 5));
    }
  }

  void _handleGeofenceNotification(GeoFenceStatus status) {
    if (!status.isInside) {
      _notificationService.showNotification(
          title: 'Geo-Fence Alert', body: '${status.name} boundary breached!');
    }
  }

  static void initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    service.startService();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground')?.listen((event) {
        service.setAsForegroundService();
      });
    }

    service.on('stopService')?.listen((event) {
      service.stopSelf();
    });

    Timer.periodic(Duration(minutes: 5), (timer) async {
      try {
        Position currentPosition = await Geolocator.getCurrentPosition();

        for (var fence in geofences) {
          double distance = Geolocator.distanceBetween(currentPosition.latitude,
              currentPosition.longitude, fence.latitude, fence.longitude);

          bool isInside = distance <= fence.radius;

          if (!isInside) {
            _notificationService.showNotification(
                title: 'Geo-Fence Alert',
                body: '${fence.name} boundary breached!');
          }
        }
      } catch (e) {
        print('Background geofencing error: $e');
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}
