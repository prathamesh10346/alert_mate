import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<Position> getCurrentLocation() async {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permissions denied');
    }
    return await Geolocator.getCurrentPosition();
  }
}
