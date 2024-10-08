import 'package:flutter/material.dart';

class EmergencyScreenTemplate extends StatelessWidget {
  final String title;
  final IconData icon;
  final String emergencyNumber;
  final List<String> instructions;
  final Color primaryColor;
  

  EmergencyScreenTemplate({
    required this.title,
    required this.icon,
    required this.emergencyNumber,
    required this.instructions,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.6), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Icon(icon, size: 100, color: primaryColor),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Emergency Instructions:',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ...instructions
                          .map((instruction) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: primaryColor),
                                    SizedBox(width: 10),
                                    Expanded(
                                        child: Text(instruction,
                                            style: TextStyle(fontSize: 20))),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                color: primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Emergency Number: $emergencyNumber',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
