import 'package:alert_mate/screen/dashboard/mycircle/mycircle.dart';
import 'package:alert_mate/screen/dashboard/setting_screen.dart';
import 'package:alert_mate/screen/services/AccidentEmergencyScreen.dart';
import 'package:alert_mate/screen/services/FireEmergencyScreen.dart';
import 'package:alert_mate/screen/services/MedicalEmergencyScreen.dart';
import 'package:alert_mate/screen/services/NaturalDisasterScreen.dart';
import 'package:alert_mate/screen/services/RescueEmergencyScreen.dart';
import 'package:alert_mate/screen/services/ViolenceEmergencyScreen.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// BottomNavProvider to manage the state of the bottom navigation
class BottomNavProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BottomNavProvider(),
      child: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.radialGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _buildMainContent(context),
              ),
              _buildBottomNavBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.white, size: 5.w),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current location',
                    style: TextStyle(color: AppColors.white, fontSize: 3.w),
                  ),
                  Text(
                    'Neo City Phase 1, Wagholi',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 3.5.w,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: AppColors.white, size: 6.w),
              SizedBox(width: 4.w),
              Icon(Icons.notifications_none, color: AppColors.white, size: 6.w),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final currentIndex = context.watch<BottomNavProvider>().currentIndex;
    switch (currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return MyCircleScreen();
      case 2:
        return SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            Text(
              'Are you in an emergency?',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 5.w,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Press the SOS button, your live location will be shared with the nearest help centre and your emergency contacts',
              style: TextStyle(color: AppColors.white, fontSize: 3.5.w),
            ),
            SizedBox(height: 4.h),
            Center(
              child: InkWell(
                onTap: () {
                  print('SOS pressed');
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 20.h,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'What\'s your emergency?',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 4.w,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildEmergencyOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCasesContent() {
    return Center(
      child: Text(
        'My Cases',
        style: TextStyle(color: AppColors.white, fontSize: 6.w),
      ),
    );
  }

  Widget _buildExploreContent() {
    return Center(
      child: Text(
        'Explore',
        style: TextStyle(color: AppColors.white, fontSize: 6.w),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: Center(
          child: Container(
            width: 35.w,
            height: 35.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent,
            ),
            child: Center(
              child: Text(
                'SOS',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 8.w,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyOptions() {
    List<Map<String, dynamic>> options = [
      {'icon': Icons.local_hospital, 'label': 'Medical'},
      {'icon': Icons.local_fire_department, 'label': 'Fire'},
      {'icon': Icons.warning, 'label': 'Natural disaster'},
      {'icon': Icons.car_crash, 'label': 'Accident'},
      {'icon': Icons.security, 'label': 'Violence'},
      {'icon': Icons.support, 'label': 'Rescue'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _navigateToEmergencyScreen(context, options[index]['label']);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(options[index]['icon'], color: AppColors.white, size: 8.w),
                SizedBox(height: 1.h),
                Text(
                  options[index]['label'],
                  style: TextStyle(color: AppColors.white, fontSize: 3.w),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToEmergencyScreen(BuildContext context, String label) {
    Widget screen;
    switch (label) {
      case 'Medical':
        screen = MedicalEmergencyScreen();
        break;
      case 'Fire':
        screen = FireEmergencyScreen();
        break;
      case 'Natural disaster':
        screen = NaturalDisasterScreen();
        break;
      case 'Accident':
        screen = AccidentEmergencyScreen();
        break;
      case 'Violence':
        screen = ViolenceEmergencyScreen();
        break;
      case 'Rescue':
        screen = RescueEmergencyScreen();
        break;
      default:
        screen =
            MedicalEmergencyScreen(); // Default to Medical if label doesn't match
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // Rest of the existing code remains unchanged
}

Widget _buildBottomNavBar(BuildContext context) {
  final provider = Provider.of<BottomNavProvider>(context);
  return Container(
    height: 8.h,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(context, Icons.home, 'Home', 0),
        _buildNavItem(context, Icons.contact_emergency, 'My Circles', 1),
        // _buildNavItem(context, Icons.explore, 'Explore', 2),
        _buildNavItem(context, Icons.settings, 'Settings', 2),
      ],
    ),
  );
}

Widget _buildNavItem(
    BuildContext context, IconData icon, String label, int index) {
  final provider = Provider.of<BottomNavProvider>(context);
  final isActive = provider.currentIndex == index;
  return GestureDetector(
    onTap: () => provider.setIndex(index),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primaryColor : Colors.grey,
          size: 6.w,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryColor : Colors.grey,
            fontSize: 3.w,
          ),
        ),
      ],
    ),
  );
}
