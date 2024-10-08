import 'dart:async'; // Add this import
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:alert_mate/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class VerifyScreen extends StatefulWidget {
  final String mobile;

  VerifyScreen({required this.mobile});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  Timer? _timer;
  int _remainingTime = 300; // 5 minutes = 300 seconds

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          opacity: 0.1,
          image: AssetImage('assets/images/Super_User_logo.png'),
          fit: BoxFit.fitWidth,
        ),
        gradient: AppColors.radialGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              SizedBox(height: SizeConfig.blockSizeVertical * 2),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 2),
              SvgPicture.asset(
                'assets/svg/Super_User_logo.svg',
                height: SizeConfig.blockSizeVertical * 15,
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 2),
              Text(
                'UNISTEP IGO',
                style: TextStyle(
                  fontSize: SizeConfig.blockSizeHorizontal * 5,
                  fontFamily: 'TradeWinds',
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 2),
              Text(
                'Fund Manager',
                style: TextStyle(
                  fontSize: SizeConfig.blockSizeHorizontal * 5.5,
                  fontFamily: 'Aclonica',
                  color: AppColors.white,
                ),
              ),
              Spacer(),
              _buildOtpInput(),
              SizedBox(height: SizeConfig.blockSizeVertical * 1),
              _buildResendAndTimer(),
              SizedBox(height: SizeConfig.blockSizeVertical * 5),
              CustomButton(
                label: 'Verify',
                onPressed: () {},
              ),
              SizedBox(height: SizeConfig.blockSizeVertical * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'OTP',
              style: TextStyle(
                color: AppColors.lightWhiteColor.withOpacity(0.7),
                fontSize: SizeConfig.blockSizeHorizontal * 4,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.blockSizeVertical * 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return CustomPaint(
              painter: GradientBorderPainter(),
              child: Container(
                width: SizeConfig.blockSizeHorizontal * 12,
                height: SizeConfig.blockSizeVertical * 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: SizeConfig.blockSizeHorizontal * 5),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          focusNodes[index + 1].requestFocus();
                        }
                      } else if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                    },
                    onEditingComplete: () {
                      if (index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResendAndTimer() {
    final minutes = _remainingTime ~/ 60;
    final seconds = _remainingTime % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: _remainingTime == 0
              ? () {
                  setState(() {
                    _remainingTime = 300;
                  });
                }
              : null,
          child: Text(
            'Resend',
            style: TextStyle(
              color: _remainingTime == 0
                  ? AppColors.lightWhiteColor
                  : AppColors.lightWhiteColor.withOpacity(0.7),
              fontSize: SizeConfig.blockSizeHorizontal * 4,
            ),
          ),
        ),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: AppColors.lightWhiteColor.withOpacity(0.7),
            fontSize: SizeConfig.blockSizeHorizontal * 4,
          ),
        ),
      ],
    );
  }
}
