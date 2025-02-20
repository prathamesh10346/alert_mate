import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:google_place_plus/google_place_plus.dart';

class MedicalFacility {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? contact;
  final String? address;
  final bool emergency24x7;
  final List<String> specialties;
  final double distance; // Distance from current location in meters

  MedicalFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.contact,
    this.address,
    this.emergency24x7 = false,
    this.specialties = const [],
    required this.distance,
  });

  factory MedicalFacility.fromGooglePlace(SearchResult place, double distance) {
    return MedicalFacility(
      id: place.placeId ?? '',
      name: place.name ?? 'Unknown',
      type: _determineFacilityType(place.types),
      latitude: place.geometry?.location?.lat ?? 0,
      longitude: place.geometry?.location?.lng ?? 0,
      address: place.formattedAddress,
      contact: '',
      emergency24x7: place.openingHours?.openNow == false,
      specialties: [], // Would need additional API call to get details
      distance: distance,
    );
  }

  static String _determineFacilityType(List<String>? types) {
    if (types == null) return 'Other';
    if (types.contains('hospital')) return 'Hospital';
    if (types.contains('doctor')) return 'Clinic';
    if (types.contains('pharmacy')) return 'Pharmacy';
    return 'Other';
  }
}

class MedicalFacilitiesProvider with ChangeNotifier {
  final GooglePlace _googlePlace;
  Position? _currentLocation;
  Set<Marker> _medicalFacilities = {};
  List<MedicalFacility> _facilities = [];
  bool _isLoading = false;
  double _searchRadius = 10000; // 10 km in meters

  Position? get currentLocation => _currentLocation;
  Set<Marker> get medicalFacilities => _medicalFacilities;
  bool get isLoading => _isLoading;
  List<MedicalFacility> get facilities => _facilities;

  MedicalFacilitiesProvider(String apiKey)
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
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = position;
      await searchNearbyFacilities();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchNearbyFacilities() async {
    if (_currentLocation == null) return;

    _isLoading = true;
    _facilities.clear();
    _medicalFacilities.clear();
    notifyListeners();

    try {
      // Search for different types of medical facilities
      final searchTypes = ['hospital', 'doctor', 'pharmacy'];

      for (String type in searchTypes) {
        final result = await _googlePlace.search.getNearBySearch(
          Location(
            lat: _currentLocation!.latitude,
            lng: _currentLocation!.longitude,
          ),
          _searchRadius.round(),
          type: type,
          keyword: 'medical',
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

              // Only add facilities within the search radius
              if (distance <= _searchRadius) {
                final facility =
                    MedicalFacility.fromGooglePlace(place, distance);
                _facilities.add(facility);

                // Create marker
                final markerIcon = _getMarkerIcon(facility.type);
                _medicalFacilities.add(
                  Marker(
                    markerId: MarkerId(facility.id),
                    position: LatLng(facility.latitude, facility.longitude),
                    icon: markerIcon,
                    infoWindow: InfoWindow(
                      title: facility.name,
                      snippet:
                          '${facility.type}\n${facility.distance.toStringAsFixed(0)}m away'
                          '${facility.address != null ? '\n${facility.address}' : ''}'
                          '${facility.contact != null ? '\n${facility.contact}' : ''}',
                    ),
                  ),
                );
              }
            }
          }
        }
      }

      // Sort facilities by distance
      _facilities.sort((a, b) => a.distance.compareTo(b.distance));
    } catch (e) {
      print('Error fetching nearby facilities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  BitmapDescriptor _getMarkerIcon(String facilityType) {
    switch (facilityType.toLowerCase()) {
      case 'hospital':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'clinic':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'pharmacy':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
    }
  }

  Future<void> updateSearchRadius(double radiusInKm) async {
    _searchRadius = radiusInKm * 1000; // Convert to meters
    await searchNearbyFacilities();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
