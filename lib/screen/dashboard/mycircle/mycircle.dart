import 'package:alert_mate/models/contact.dart';
import 'package:alert_mate/providers/contacts_provider.dart';
import 'package:alert_mate/screen/dashboard/main_screen.dart';
import 'package:alert_mate/screen/dashboard/mycircle/add_contact_screen.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyCircleScreen extends StatefulWidget {
  @override
  _MyCircleScreenState createState() => _MyCircleScreenState();
}

class _MyCircleScreenState extends State<MyCircleScreen> {
  bool _isDetailView = false;
  String _selectedCircle = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContactsProvider>(context, listen: false).loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainScreen()));
        return true;
      },
      child: Consumer<ContactsProvider>(
        builder: (context, contactsProvider, child) {
          return _isDetailView
              ? _buildDetailView(contactsProvider, context)
              : _buildMainView(contactsProvider);
        },
      ),
    );
  }

  Widget _buildMainView(ContactsProvider contactsProvider) {
    final circles = contactsProvider.circles;

    return Column(
      children: [
        _buildHeader('Emergency Circles', false),
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: circles.length,
            itemBuilder: (context, index) {
              final circle = circles[index];
              final contactCount =
                  contactsProvider.getContactCountByCircle(circle);
              return _buildCircleItem(
                circle,
                '$contactCount Contacts',
                _getCircleColor(circle),
                onTap: () {
                  setState(() {
                    _isDetailView = true;
                    _selectedCircle = circle;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(
      ContactsProvider contactsProvider, BuildContext context) {
    final contacts = contactsProvider.getContactsByCircle(_selectedCircle);

    return Column(
      children: [
        _buildHeader(_selectedCircle, true),
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _buildContactItem(contact);
            },
          ),
        ),
      ],
    );
  }

  Color _getCircleColor(String circle) {
    switch (circle) {
      case 'Family':
        return Colors.blue;
      case 'General':
        return Colors.green;
      case 'Relatives':
        return Colors.orange;
      case 'Friends':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => EmergencyContactScreen()),
              );
            },
            child: Row(
              children: [
                // Text(
                //   title,
                //   style: TextStyle(
                //       fontSize: 5.w,
                //       color: Colors.white,
                //       fontWeight: FontWeight.bold),
                // ),
                Text(
                  '+ Add Contact',
                  style: TextStyle(fontSize: 3.5.w, color: Colors.orange),
                ),
              ],
            ),
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
        child: const Row(
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

  Widget _buildCircleItem(String name, String contacts, Color color,
      {required Null Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
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
                  style: TextStyle(
                      color: color, fontSize: 6.w, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 4.5.w, fontWeight: FontWeight.bold)),
                Text(contacts,
                    style: TextStyle(
                        fontSize: 3.5.w,
                        color: const Color.fromARGB(255, 255, 255, 255))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 6.w,
            backgroundImage:
                const AssetImage('assets/images/placeholder_avatar.png'),
          ),
          SizedBox(width: 4.w),
          Text(contact.name, style: TextStyle(fontSize: 4.5.w)),
        ],
      ),
    );
  }
}
