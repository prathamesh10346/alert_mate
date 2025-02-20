import 'package:alert_mate/screen/auth_screens/login_screen.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation opacityAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    opacityAnimation = Tween(begin: 0.1, end: 1.0).animate(controller);
    Future.delayed(
      Duration(seconds: 3),
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                      opacity: opacityAnimation.value,
                      child: Text(
                        'ALERT MATE',
                        style: TextStyle(
                          fontSize: 10.w,
                          fontFamily: 'TradeWinds',
                          color: AppColors.white,
                        ),
                      ));
                },
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 2),
            ],
          ),
        ),
      ),
    );
  }
}
