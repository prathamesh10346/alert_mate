import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyDialog extends StatefulWidget {
  final Function() onOkPressed;
  final Function() onEmergencyPressed;
  final Function() onTimeExpired;
  final int totalSeconds;

  const EmergencyDialog({
    Key? key,
    required this.onOkPressed,
    required this.onEmergencyPressed,
    required this.onTimeExpired,
    this.totalSeconds = 30,
  }) : super(key: key);

  @override
  State<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends State<EmergencyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;
  int _secondsLeft = 30;
  bool _hasTriggeredEmergency = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalSeconds;

    _controller = AnimationController(
      duration: Duration(seconds: widget.totalSeconds),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_controller);

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));

    // Listen for animation completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasTriggeredEmergency) {
        _hasTriggeredEmergency = true;
        widget.onTimeExpired();
      }
    });

    // Update countdown timer
    _controller.addListener(() {
      setState(() {
        _secondsLeft = (widget.totalSeconds * (1 - _controller.value)).ceil();
      });
    });

    _controller.forward();

    // Setup periodic haptic feedback
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to handle safe areas and screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: screenSize.width,
        height: screenSize.height,
        padding: EdgeInsets.only(
          top: safePadding.top + 20,
          bottom: safePadding.bottom + 20,
          left: 20,
          right: 20,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Pulse circles
                ...List.generate(3, (index) {
                  return Transform.scale(
                    scale: _pulseAnimation.value - (index * 0.1),
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.1 - (index * 0.02)),
                      ),
                    ),
                  );
                }),

                // Main dialog
                Container(
                  width: 340,
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height -
                        safePadding.top -
                        safePadding.bottom -
                        40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: LinearProgressIndicator(
                                value: _animation.value,
                                backgroundColor: Colors.grey[800],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.red),
                                minHeight: 4,
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Header with icon
                                  Row(
                                    children: [
                                      _buildPulsingIcon(),
                                      SizedBox(width: 12),
                                      Text(
                                        'Emergency Alert!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),

                                  // Alert box
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Accident Detected',
                                          style: TextStyle(
                                            color: Colors.red[400],
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Emergency services will be contacted in $_secondsLeft seconds if no response is received.',
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 24),

                                  // Action buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _buildButton(
                                        'I\'m OK',
                                        Colors.grey[700]!,
                                        widget.onOkPressed,
                                      ),
                                      SizedBox(width: 12),
                                      _buildButton(
                                        'Get Help Now',
                                        Colors.red,
                                        widget.onEmergencyPressed,
                                        icon: Icons.phone,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPulsingIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed,
      {IconData? icon}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
