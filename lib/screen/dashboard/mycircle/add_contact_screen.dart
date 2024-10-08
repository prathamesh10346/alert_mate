import 'package:alert_mate/utils/app_color.dart';
import 'package:flutter/material.dart';

class EmergencyContactScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Matching the dark background
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.radialGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.medical_services,
                        color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Emergency Contact',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                buildInfoRow('Name', 'Atul'),
                buildInfoRow('Age', '20'),
                buildInfoRow('Relationship', 'Friend'),
                buildInfoRow('City', 'Pune'),
                buildInfoRow('Blood type', 'O+'),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: const Text(
                      'Add Contact',
                      style: TextStyle(color: Colors.orange, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }
}
