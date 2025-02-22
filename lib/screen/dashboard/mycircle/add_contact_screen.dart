import 'package:alert_mate/models/contact.dart';
import 'package:alert_mate/providers/contacts_provider.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EmergencyContactScreen extends StatefulWidget {
  final String? circleType;

  const EmergencyContactScreen({this.circleType});

  @override
  _EmergencyContactScreenState createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  String _selectedCircle = 'General';

  @override
  void initState() {
    super.initState();
    if (widget.circleType != null) {
      _selectedCircle = widget.circleType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 20),
                    buildTextField('Name', _nameController),
                    buildTextField('Phone Number', _phoneController),
                    buildTextField('Email', _emailController),
                    buildTextField('Relationship', _relationshipController),
                    buildTextField('City', _cityController),
                    buildTextField('Age', _ageController),
                    buildTextField('Blood Type', _bloodTypeController),
                    buildCircleDropdown(),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.all(16),
                        ),
                        onPressed: _saveContact,
                        child: Text('Save Contact'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.orange),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.orange),
          ),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget buildCircleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCircle,
      dropdownColor: Colors.grey[800],
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Circle',
        labelStyle: TextStyle(color: Colors.orange),
      ),
      items: ['General', 'Family', 'Relatives', 'Friends']
          .map((circle) => DropdownMenuItem(
                value: circle,
                child: Text(circle),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCircle = value!;
        });
      },
    );
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: DateTime.now().toString(),
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        relationship: _relationshipController.text,
        city: _cityController.text,
        age: _ageController.text,
        bloodType: _bloodTypeController.text,
        circleType: _selectedCircle,
      );

      Provider.of<ContactsProvider>(context, listen: false)
          .saveContact(contact)
          .then((_) {
        Navigator.pop(context);
      });
    }
  }
}
