import 'package:alert_mate/providers/emergency_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class EmergencyServicesScreen extends StatefulWidget {
  final String serviceType; // 'police' or 'fire'
  final String title;

  EmergencyServicesScreen({
    required this.serviceType,
    required this.title,
  });

  @override
  _EmergencyServicesScreenState createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  double _currentRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              widget.serviceType == 'police' 
                  ? Icons.local_police 
                  : Icons.local_fire_department,
            ),
            onPressed: () => _showServiceInfo(),
          ),
        ],
      ),
      body: Consumer<EmergencyServicesProvider>(
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
                markers: provider.serviceLocations,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Search Radius: ${_currentRadius.toStringAsFixed(1)} km',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (provider.locations.isNotEmpty)
                              Text(
                                '${provider.locations.length} locations found',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
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

  void _showServiceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(
                widget.serviceType == 'police' 
                    ? Icons.local_police 
                    : Icons.local_fire_department,
                color: widget.serviceType == 'police' 
                    ? Colors.blue 
                    : Colors.orange,
              ),
              title: Text(
                widget.serviceType == 'police' 
                    ? 'Emergency: 100' 
                    : 'Emergency: 101'
              ),
              subtitle: Text('24x7 Emergency Services'),
            ),
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
}