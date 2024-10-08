import 'package:alert_mate/screen/auth_screens/load_screen.dart';
import 'package:alert_mate/utils/app_color.dart';
import 'package:alert_mate/utils/size_config.dart';
import 'package:alert_mate/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _controller;
  bool _isValidNumber = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.05,
        ),
        gradient: AppColors.radialGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 7.h),
              SvgPicture.asset(
                'assets/svg/logo.svg',
                height: 15.h,
              ),
              SizedBox(height: 2.h),
              Text(
                'ALERT MATE',
                style: TextStyle(
                  fontSize: 5.w,
                  fontFamily: 'TradeWinds',
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomPaint(
                      painter: GradientBorderPainter(),
                      child: Container(
                        height: 5.8.h,
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: _isValidNumber
                                ? Colors.transparent
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mail_outline, color: AppColors.white),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 4.w,
                                  color: AppColors.white,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(bottom: 10),
                                  hintText: 'Email',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: AppColors.white),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isValidNumber = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    CustomPaint(
                      painter: GradientBorderPainter(),
                      child: Container(
                        height: 5.8.h,
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: _isValidNumber
                                ? Colors.transparent
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.key, color: AppColors.white),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: 4.w,
                                  color: AppColors.white,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(bottom: 10),
                                  hintText: 'Password',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: AppColors.white),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isValidNumber = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SizedBox(height: 0.7.h),
                    // Row(
                    //   children: [
                    //     Text(
                    //       "OTP will be sent to your mobile number",
                    //       style: TextStyle(
                    //         color: AppColors.white,
                    //         fontSize: 3.w,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 4.h),
                    CustomButton(
                      label: 'Login',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => HomeLoadingScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
