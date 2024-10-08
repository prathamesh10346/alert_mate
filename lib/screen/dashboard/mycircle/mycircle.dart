import 'package:flutter/material.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';

class MyCircleScreen extends StatefulWidget {
  @override
  _MyCircleScreenState createState() => _MyCircleScreenState();
}

class _MyCircleScreenState extends State<MyCircleScreen> {
  bool _isDetailView = false;
  String _selectedCircle = '';

  @override
  Widget build(BuildContext context) {
    return _isDetailView ? _buildDetailView() : _buildMainView();
  }

  Widget _buildMainView() {
    return Column(
      children: [
        _buildHeader('Emergency circle', true),
        _buildSearchBar(),
        Expanded(
          child: ListView(
            children: [
              _buildCircleItem('General', '2 Contacts', Colors.green),
              _buildCircleItem('Family', '5 Contacts', Colors.blue),
              _buildCircleItem('Relatives', '6 Contacts', Colors.orange),
              _buildCircleItem('Relatives 1', '2 Contacts', Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView() {
    return Column(
      children: [
        _buildHeader(_selectedCircle, false),
        _buildSearchBar(),
        Expanded(
          child: ListView(
            children: [
              _buildContactItem('Dad'),
              _buildContactItem('Sister'),
              _buildContactItem('George Thomas'),
              _buildContactItem('Naina alvas'),
              _buildContactItem('Albin'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, bool isMainView) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isMainView)
            GestureDetector(
              onTap: () => setState(() => _isDetailView = false),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          Text(
            title,
            style: TextStyle(fontSize: 5.w, fontWeight: FontWeight.bold),
          ),
          Text(
            '+ Add ${isMainView ? 'Circle' : 'Contact'}',
            style: TextStyle(fontSize: 3.5.w, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                ),
              ),
            ),
            Icon(Icons.mic, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleItem(String name, String contacts, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDetailView = true;
          _selectedCircle = name;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: TextStyle(color: color, fontSize: 6.w, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 4.5.w, fontWeight: FontWeight.bold)),
                Text(contacts, style: TextStyle(fontSize: 3.5.w, color: const Color.fromARGB(255, 255, 255, 255))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(String name) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 6.w,
            backgroundImage: AssetImage('assets/images/placeholder_avatar.png'),
          ),
          SizedBox(width: 4.w),
          Text(name, style: TextStyle(fontSize: 4.5.w)),
        ],
      ),
    );
  }
}