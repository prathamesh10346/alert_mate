import 'package:alert_mate/providers/contacts_provider.dart';
import 'package:alert_mate/providers/theme_provider.dart';
import 'package:alert_mate/screen/dashboard/mycircle/mycircle.dart';
import 'package:alert_mate/screen/dashboard/setting_screen.dart';
import 'package:alert_mate/screen/devies_details/AccidentDetectionScreen.dart';
import 'package:alert_mate/screen/devies_details/geofencing_screen.dart';
import 'package:alert_mate/screen/devies_details/women_safety_screen.dart';
import 'package:alert_mate/screen/services/AccidentEmergencyScreen.dart';
import 'package:alert_mate/screen/services/FireEmergencyScreen.dart';
import 'package:alert_mate/screen/services/MedicalEmergencyScreen.dart';
import 'package:alert_mate/screen/services/NaturalDisasterScreen.dart';
import 'package:alert_mate/screen/services/RescueEmergencyScreen.dart';
import 'package:alert_mate/screen/services/SOSService.dart';
import 'package:alert_mate/screen/services/ViolenceEmergencyScreen.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart'; // Make sure to add this package

import 'package:shared_preferences/shared_preferences.dart';

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

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _currentAddress = "Fetching location...";
  Position? _currentPosition;
  bool _isLoading = true;
  late AnimationController _sosAnimationController;
  bool _isEmergency = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _getCurrentLocation();
    _sosAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sosAnimationController.dispose();
    super.dispose();
  }

  // Load saved location from SharedPreferences
  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentAddress =
          prefs.getString('saved_address') ?? "Fetching location...";
    });
  }

  // Save location to SharedPreferences
  Future<void> _saveLocation(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_address', address);
  }

  // Check and request location permissions
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Location services are disabled. Please enable the services')),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return false;
    }

    return true;
  }

  // Get current location and address
  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String newAddress = "${place.subLocality}, ${place.locality}";

        setState(() {
          _currentPosition = position;
          _currentAddress = newAddress;
          _isLoading = false;
        });

        await _saveLocation(newAddress);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  final SOSService _sosService = SOSService();

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Theme(
      data: themeProvider.currentTheme,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.getDarkGradient()
                : AppColors.getLightGradient(),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(isDark),
                Expanded(
                  child: _buildMainContent(context, isDark),
                ),
                _buildBottomNavBar(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.black12 : Colors.white10,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primaryColor,
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 2.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current location',
                      style: TextStyle(
                        color: isDark ? AppColors.lightGrey : AppColors.grey,
                        fontSize: 3.w,
                      ),
                    ),
                    _isLoading
                        ? SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          )
                        : Text(
                            _currentAddress,
                            style: TextStyle(
                              color: isDark ? AppColors.white : AppColors.black,
                              fontSize: 3.5.w,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
                SizedBox(width: 1.w),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    color: AppColors.primaryColor,
                    size: 5.w,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isDark) {
    final currentIndex = context.watch<BottomNavProvider>().currentIndex;

    switch (currentIndex) {
      case 0:
        return _buildHomeContent(isDark);
      case 1:
        return MyCircleScreen();
      case 2:
        return SettingsScreen();
      default:
        return _buildHomeContent(isDark);
    }
  }

  Widget _buildHomeContent(bool isDark) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Are you in an emergency?',
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.black,
                  fontSize: 6.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            FadeInRight(
              duration: const Duration(milliseconds: 700),
              child: Text(
                'Press the SOS button, your live location will be shared with the nearest help centre and your emergency contacts',
                style: TextStyle(
                  color: isDark ? AppColors.lightGrey : AppColors.grey,
                  fontSize: 3.5.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            _buildSOSButton(isDark),
            SizedBox(height: 4.h),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s your emergency?',
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.black,
                        fontSize: 4.5.w,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildEmergencyOptions(isDark),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          try {
            setState(() {
              _isEmergency = !_isEmergency;
            });

            if (_isEmergency) {
              // Start animations
              _sosAnimationController.repeat(reverse: true);

              // Check for emergency contacts
              final contacts = await _sosService.getEmergencyContacts();
              if (contacts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Please add emergency contacts in settings first')),
                );
                setState(() => _isEmergency = false);
                return;
              }

              // Activate SOS if we have the current position
              if (_currentPosition != null) {
                await _sosService.activateSOS(_currentPosition!);

                // Show confirmation to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'SOS activated! Emergency contacts will be notified.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Waiting for location data...')),
                );
              }
            } else {
              // Deactivate SOS
              _sosService.deactivateSOS();
              _sosAnimationController.reset();
              _sosAnimationController.stop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('SOS deactivated')),
              );
            }

            // Haptic feedback
            HapticFeedback.heavyImpact();
          } catch (e) {
            print('Error in SOS activation: $e');
            setState(() => _isEmergency = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error activating SOS. Please try again.')),
            );
          }
        },
        child: AnimatedBuilder(
          animation: _sosAnimationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Multiple ripple animations for active state
                if (_isEmergency)
                  ...List.generate(3, (index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(seconds: 2),
                      curve: Curves.easeOutQuad,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: (1.0 - value) * 0.7,
                          child: Transform.scale(
                            scale: 0.5 + (value * 0.8) + (index * 0.2),
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(
                                  AppColors.dangerColor,
                                  Colors.red.shade800,
                                  _sosAnimationController.value,
                                )!
                                    .withOpacity(0.3 - (index * 0.1)),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                // Spinning effect for active state
                if (_isEmergency)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 2 * 3.14159),
                    duration: Duration(seconds: 4),
                    curve: Curves.linear,
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value,
                        child: Container(
                          width: 42.w,
                          height: 42.w,
                          child: CustomPaint(
                            painter: EmergencyPulseRingPainter(
                              color: AppColors.dangerColor,
                              dashWidth: 12,
                              dashSpace: 10,
                              animation: _sosAnimationController.value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Main SOS button with pulse effect
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: _isEmergency ? 0.9 : 1.0,
                    end: _isEmergency ? 1.1 : 1.0,
                  ),
                  duration: Duration(milliseconds: _isEmergency ? 800 : 300),
                  curve: _isEmergency ? Curves.easeInOut : Curves.bounceOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: _isEmergency
                          ? scale * (0.95 + _sosAnimationController.value * 0.1)
                          : scale,
                      child: Container(
                        width: 35.w,
                        height: 35.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isEmergency
                              ? AppColors.getDangerGradient()
                              : AppColors.getAccentGradient(),
                          boxShadow: [
                            BoxShadow(
                              color: _isEmergency
                                  ? AppColors.dangerColor.withOpacity(
                                      0.5 + _sosAnimationController.value * 0.3)
                                  : AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: _isEmergency
                                  ? 25 + (_sosAnimationController.value * 15)
                                  : 20,
                              spreadRadius: _isEmergency
                                  ? 3 + (_sosAnimationController.value * 4)
                                  : 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShakeAnimatedWidget(
                                enabled: _isEmergency,
                                duration: Duration(milliseconds: 1000),
                                shakeAngle: Rotation.deg(z: 1),
                                curve: Curves.elasticOut,
                                child: Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 8.w,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  _isEmergency ? 'ACTIVE' : 'PRESS',
                                  key: ValueKey(_isEmergency),
                                  style: TextStyle(
                                    color: AppColors.white.withOpacity(0.8),
                                    fontSize: 3.w,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyOptions(bool isDark) {
    List<Map<String, dynamic>> options = [
      {
        'icon': Icons.local_hospital,
        'label': 'Medical',
        'color': Color(0xFFE53935),
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'Fire',
        'color': Color(0xFFFF9800),
      },
      {
        'icon': Icons.local_police,
        'label': 'Police Stations',
        'color': Color(0xFF8BC34A),
      },
      {
        'icon': Icons.car_crash,
        'label': 'Accident',
        'color': Color(0xFF3F51B5),
      },
      {
        'icon': Icons.security,
        'label': 'Women Safety',
        'color': Color(0xFF9C27B0),
      },
      {
        'icon': Icons.support,
        'label': 'Rescue',
        'color': Color(0xFF00BCD4),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: Duration(milliseconds: 600 + (index * 100)),
          child: GestureDetector(
            onTap: () {
              _navigateToEmergencyScreen(context, options[index]['label']);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    options[index]['color'].withOpacity(0.8),
                    options[index]['color'].withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: options[index]['color'].withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      options[index]['icon'],
                      color: AppColors.white,
                      size: 8.w,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Text(
                    options[index]['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 3.5.w,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
        screen = MedicalFacilitiesScreen();
        break;
      case 'Fire':
        screen = EmergencyServicesScreen(
          serviceType: 'fire',
          title: 'Nearby Fire Stations',
        );
        break;
      case 'Police Stations':
        screen = EmergencyServicesScreen(
          serviceType: 'police',
          title: 'Nearby Police Stations',
        );
        break;
      case 'Accident':
        screen = AccidentDetectionScreen();
        break;
      case 'Women Safety':
        screen = WomenSafetyScreen();
        break;
      case 'Rescue':
        screen = GeofencingScreen();
        break;
      default:
        screen = GeofencingScreen();
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
    );
  }
}

Widget _buildBottomNavBar(BuildContext context, bool isDark) {
  final provider = Provider.of<BottomNavProvider>(context);

  return Container(
    height: 9.h,
    decoration: BoxDecoration(
      color: isDark ? Colors.black12 : Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(context, Icons.home_rounded, 'Home', 0, isDark),
        _buildNavItem(
            context, Icons.people_alt_rounded, 'My Circles', 1, isDark),
        _buildNavItem(context, Icons.settings_rounded, 'Settings', 2, isDark),
      ],
    ),
  );
}

Widget _buildNavItem(
    BuildContext context, IconData icon, String label, int index, bool isDark) {
  final provider = Provider.of<BottomNavProvider>(context);
  final isActive = provider.currentIndex == index;

  return GestureDetector(
    onTap: () => provider.setIndex(index),
    child: FadeIn(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryColor.withOpacity(isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.primaryColor
                  : isDark
                      ? AppColors.lightGrey
                      : AppColors.grey,
              size: 6.w,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppColors.primaryColor
                    : isDark
                        ? AppColors.lightGrey
                        : AppColors.grey,
                fontSize: 3.w,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EmergencyPulseRingPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double animation;

  EmergencyPulseRingPainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withOpacity(0.6 + (animation * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Draw dashed circle
    drawDashedCircle(
      canvas: canvas,
      center: center,
      radius: radius - 5,
      dashWidth: dashWidth,
      dashSpace: dashSpace,
      paint: paint,
      startAngle: animation * 2 * 3.14159,
    );
  }

  void drawDashedCircle({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double dashWidth,
    required double dashSpace,
    required Paint paint,
    double startAngle = 0,
  }) {
    final double dashAngle = dashWidth / radius;
    final double spaceAngle = dashSpace / radius;
    double currentAngle = startAngle;

    while (currentAngle < startAngle + 2 * 3.14159) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + spaceAngle;
    }
  }

  @override
  bool shouldRepaint(EmergencyPulseRingPainter oldDelegate) =>
      animation != oldDelegate.animation;
}

// Add this Animation Widget for the shaking effect
// Fix for the ShakeAnimatedWidget
class ShakeAnimatedWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;
  final Rotation shakeAngle;
  final Curve curve;

  const ShakeAnimatedWidget({
    Key? key,
    required this.child,
    required this.enabled,
    required this.duration,
    required this.shakeAngle,
    required this.curve,
  }) : super(key: key);

  @override
  _ShakeAnimatedWidgetState createState() => _ShakeAnimatedWidgetState();
}

class _ShakeAnimatedWidgetState extends State<ShakeAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    );

    if (widget.enabled) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ShakeAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double animationValue =
            widget.enabled ? (_animation.value - 0.5) * 2 : 0.0;
        return Transform.rotate(
          angle: widget.shakeAngle.z * animationValue * 0.05,
          child: widget.child,
        );
      },
    );
  }
}

class Rotation {
  final double x;
  final double y;
  final double z;

  const Rotation({this.x = 0, this.y = 0, this.z = 0});

  factory Rotation.deg({double x = 0, double y = 0, double z = 0}) {
    return Rotation(
      x: x * 3.14159 / 180,
      y: y * 3.14159 / 180,
      z: z * 3.14159 / 180,
    );
  }
}
