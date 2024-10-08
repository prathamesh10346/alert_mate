import 'package:alert_mate/screen/dashboard/mycircle/add_contact_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool emailAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Personal Information', [
                  _buildInfoField('Name'),
                  _buildInfoField('Email'),
                ]),
                SizedBox(height: 20),
                _buildSection('Emergency Contacts', [
                  _buildContactItem('John Smith - Brother'),
                  _buildContactItem('Lisa Johnson - Friend'),
                  _buildAddContactButton(),
                ]),
                SizedBox(height: 20),
                _buildSection('Notifications', [
                  _buildSwitchItem('Push Notifications', pushNotifications,
                      (value) {
                    setState(() => pushNotifications = value);
                  }),
                  _buildSwitchItem('Email Alerts', emailAlerts, (value) {
                    setState(() => emailAlerts = value);
                  }),
                ]),
                SizedBox(height: 20),
                _buildSection('App Preferences', [
                  _buildPreferenceItem('Language', 'English'),
                  _buildPreferenceItem('Theme', 'Dark'),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(String contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(contact, style: TextStyle(color: Colors.white)),
          ElevatedButton(
            child: Text('Edit', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAddContactButton() {
    return TextButton(
      child: Text('+ Add New Contact', style: TextStyle(color: Colors.blue)),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EmergencyContactScreen()),
        );
      },
    );
  }

  Widget _buildSwitchItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white)),
          Text(value, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
