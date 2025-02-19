// fake_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({Key? key}) : super(key: key);

  @override
  _FakeCallScreenState createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool isCallAnswered = false;
  Timer? callTimer;
  int secondsElapsed = 0;
  static const platform = MethodChannel('com.your.app/fake_call');

  @override
  void initState() {
    super.initState();
    // Start the fake call
    platform.invokeMethod('simulateFakeCall');
  }

  void _answerCall() {
    setState(() {
      isCallAnswered = true;
    });
    _startCallTimer();
  }

  void _startCallTimer() {
    callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        secondsElapsed++;
      });
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    callTimer?.cancel();
    await platform.invokeMethod('stopFakeCall');
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: isCallAnswered ? _buildOngoingCallUI() : _buildIncomingCallUI(),
        ),
      ),
    );
  }

  Widget _buildIncomingCallUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(Icons.person, size: 60, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            Text(
              'Mom',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Incoming call...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCallButton(
                icon: Icons.call_end,
                color: Colors.red,
                onPressed: _endCall,
              ),
              _buildCallButton(
                icon: Icons.call,
                color: Colors.green,
                onPressed: _answerCall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingCallUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(Icons.person, size: 60, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            Text(
              'Mom',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _formatDuration(secondsElapsed),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCallButton(
                icon: Icons.volume_up,
                color: Colors.grey[700]!,
                onPressed: () {},
                size: 50,
              ),
              _buildCallButton(
                icon: Icons.mic,
                color: Colors.grey[700]!,
                onPressed: () {},
                size: 50,
              ),
              _buildCallButton(
                icon: Icons.call_end,
                color: Colors.red,
                onPressed: _endCall,
                size: 50,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}