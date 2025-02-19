import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<Map<String, String>> fetchLocationDetails() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return {'Error': 'Location permissions are denied'};
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          'Latitude': position.latitude.toString(),
          'Longitude': position.longitude.toString(),
          'Altitude': '${position.altitude.toStringAsFixed(2)} meters',
          'Speed': '${position.speed.toStringAsFixed(2)} m/s',
          'Accuracy': '${position.accuracy.toStringAsFixed(2)} meters',
          'Street': place.street ?? 'Unknown',
          'Sublocality': place.subLocality ?? 'Unknown',
          'Locality': place.locality ?? 'Unknown',
          'Administrative Area': place.administrativeArea ?? 'Unknown',
          'Postal Code': place.postalCode ?? 'Unknown',
          'Country': place.country ?? 'Unknown',
        };
      }
      return {'Error': 'Unable to fetch address details'};
    } catch (e) {
      return {'Error': 'Failed to get location details: $e'};
    }
  }
}