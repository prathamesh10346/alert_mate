import 'package:alert_mate/providers/medical_facilities_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class MedicalFacilitiesScreen extends StatefulWidget {
  @override
  _MedicalFacilitiesScreenState createState() =>
      _MedicalFacilitiesScreenState();
}

class _MedicalFacilitiesScreenState extends State<MedicalFacilitiesScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  double _currentRadius = 10.0; // Default 10km radius

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Medical Facilities'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showLegend,
          ),
        ],
      ),
      body: Consumer<MedicalFacilitiesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.currentLocation == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Location access required'),
                  ElevatedButton(
                    onPressed: () => provider.getCurrentLocation(),
                    child: Text('Grant Access'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    provider.currentLocation!.latitude,
                    provider.currentLocation!.longitude,
                  ),
                  zoom: 14,
                ),
                markers: provider.medicalFacilities,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Search Radius: ${_currentRadius.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: 8),
                        Slider(
                          value: _currentRadius,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: '${_currentRadius.toStringAsFixed(1)} km',
                          onChanged: (value) {
                            setState(() => _currentRadius = value);
                            provider.updateSearchRadius(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem('Hospital', Colors.red),
            _legendItem('Clinic', Colors.blue),
            _legendItem('Pharmacy', Colors.green),
            _legendItem('Other Facilities', Colors.purple),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
