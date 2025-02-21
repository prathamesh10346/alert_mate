import 'dart:async';

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
    speech = stt.SpeechToText();
    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    opacityAnimation = Tween(begin: 0.1, end: 1.0).animate(controller);
    Future.delayed(
      Duration(seconds: 3),
      () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            // Animation controller setup
            final dialogController = AnimationController(
              duration: const Duration(seconds: 30),
              vsync: Navigator.of(context),
            );
            final animation = Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(dialogController);
            dialogController.forward();

            // Set up TTS
            var ttsCount = 0;
            Timer(const Duration(seconds: 10), () async {
              if (ttsCount < 1) {
                await flutterTts.setLanguage("en-US");
                await speakAndListen("Are you okay? Respond with yes or no");
                ttsCount++;
                Timer(const Duration(seconds: 3), () async {
                  if (ttsCount < 1) {
                    await speakAndListen(
                        "Are you okay? Respond with yes or no");
                    ttsCount++;
                  }
                });
              }
            });

            // Initialize speech recognition
            requestMicrophonePermission().then((granted) {
              if (granted) {
                checkSpeechRecognitionAvailability();
              } else {
                print('Microphone permission denied');
              }
            });

            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(400, 400),
                      painter: CircularTimerPainter(
                        progress: animation.value,
                        backgroundColor: Colors.grey[800]!,
                        progressColor: Colors.red,
                      ),
                    );
                  },
                ),
                AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    'Accident Detected!',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you okay? Emergency services will be contacted in 30 seconds if no response.',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        stopListening();
                        Navigator.pop(context);
                      },
                      child: Text('I\'m OK'),
                    ),
                    TextButton(
                      onPressed: () {
                        stopListening();
                        Navigator.pop(context);
                        // _contactEmergencyServices(accidentData, contacts);
                      },
                      child: Text(
                        'Get Help Now',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> requestMicrophonePermission() async {
    var permissionStatus = await Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      var result = await Permission.microphone.request();
      return result.isGranted;
    } else {
      return true;
    }
  }

  void checkSpeechRecognitionAvailability() async {
    bool available = await speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );
    if (available) {
      print('Speech recognition available');
    } else {
      print('Speech recognition not available');
    }
  }

  void startListening() {
    print("Listening....");

    if (!isListening) {
      lastWords = '';
      speech.listen(
        onResult: (result) {
          setState(() {
            lastWords = result.recognizedWords;
            print('Recognized words: $lastWords');
            if (lastWords.toLowerCase().contains('yes')) {
              stopListening();
              Navigator.pop(context);
            } else if (lastWords.toLowerCase().contains('no')) {
              stopListening();
              // _contactEmergencyServices(accidentData, contacts);
              Navigator.pop(context);
            }
          });
        },
        listenFor: const Duration(seconds: 20), // Set to listen for 20 seconds
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
        cancelOnError: true,
      );
      setState(() => isListening = true);
    }
  }

  void stopListening() {
    if (isListening) {
      speech.stop();
      setState(() => isListening = false);
    }
  }

  Future<void> speakAndListen(String text) async {
    await flutterTts.setLanguage("en-US");

    // Set up the completion handler to start listening after TTS completes
    flutterTts.setCompletionHandler(() {
      startListening();
    });

    // Speak the text
    await flutterTts.speak(text);
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
