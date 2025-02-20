import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place_plus/google_place_plus.dart';
import 'dart:async';

class EmergencyServicesProvider with ChangeNotifier {
  final GooglePlace _googlePlace;
  Position? _currentLocation;
  Set<Marker> _serviceLocations = {};
  List<EmergencyServiceLocation> _locations = [];
  bool _isLoading = false;
  double _searchRadius = 10000; // 10 km in meters
  final String _serviceType; // 'police' or 'fire_station'

  Position? get currentLocation => _currentLocation;
  Set<Marker> get serviceLocations => _serviceLocations;
  bool get isLoading => _isLoading;
  List<EmergencyServiceLocation> get locations => _locations;

  EmergencyServicesProvider(String apiKey, this._serviceType)
      : _googlePlace = GooglePlace(apiKey) {
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = position;
      await searchNearbyServices();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchNearbyServices() async {
    if (_currentLocation == null) return;

    _isLoading = true;
    _locations.clear();
    _serviceLocations.clear();
    notifyListeners();

    try {
      final result = await _googlePlace.search.getNearBySearch(
        Location(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
        ),
        _searchRadius.round(),
        type: _serviceType,
      );

      if (result?.results != null) {
        for (var place in result!.results!) {
          if (place.geometry?.location != null) {
            double distance = Geolocator.distanceBetween(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              place.geometry!.location!.lat!,
              place.geometry!.location!.lng!,
            );

            if (distance <= _searchRadius) {
              final location =
                  EmergencyServiceLocation.fromGooglePlace(place, distance);
              _locations.add(location);

              final markerIcon = _getMarkerIcon();
              _serviceLocations.add(
                Marker(
                  markerId: MarkerId(location.id),
                  position: LatLng(location.latitude, location.longitude),
                  icon: markerIcon,
                  infoWindow: InfoWindow(
                    title: location.name,
                    snippet: '${location.distance.toStringAsFixed(0)}m away'
                        '${location.address != null ? '\n${location.address}' : ''}',
                  ),
                ),
              );
            }
          }
        }
      }

      _locations.sort((a, b) => a.distance.compareTo(b.distance));
    } catch (e) {
      print('Error fetching nearby services: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  BitmapDescriptor _getMarkerIcon() {
    return _serviceType == 'police'
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  Future<void> updateSearchRadius(double radiusInKm) async {
    _searchRadius = radiusInKm * 1000;
    await searchNearbyServices();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class EmergencyServiceLocation {
  final String id;
  final String name;
  final String type; // Police, Fire
  final double latitude;
  final double longitude;
  final String? contact;
  final String? address;
  final bool is24x7;
  final double distance; // Distance from current location in meters

  EmergencyServiceLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.contact,
    this.address,
    this.is24x7 = true,
    required this.distance,
  });

  factory EmergencyServiceLocation.fromGooglePlace(
      SearchResult place, double distance) {
    return EmergencyServiceLocation(
      id: place.placeId ?? '',
      name: place.name ?? 'Unknown',
      type: _determineServiceType(place.types),
      latitude: place.geometry?.location?.lat ?? 0,
      longitude: place.geometry?.location?.lng ?? 0,
      address: place.formattedAddress,
      contact: '',
      is24x7: true,
      distance: distance,
    );
  }

  static String _determineServiceType(List<String>? types) {
    if (types == null) return 'Other';
    if (types.contains('police')) return 'Police';
    if (types.contains('fire_station')) return 'Fire';
    return 'Other';
  }
}
