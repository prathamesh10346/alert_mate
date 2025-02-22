import 'dart:async';

import 'package:alert_mate/screen/auth_screens/login_screen.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:alert_mate/widgets/circular_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacityAnimation;

  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText speech;
  bool isListening = false;
  String lastWords = '';

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    opacityAnimation = Tween(begin: 0.1, end: 1.0).animate(controller);
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    });
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
