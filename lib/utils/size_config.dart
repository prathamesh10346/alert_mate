import 'package:flutter/widgets.dart';

class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double textMultiplier;
  static late double imageSizeMultiplier;
  static late double heightMultiplier;

  static bool isPortrait = true;
  static bool isMobilePortrait = false;

  void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    if (screenWidth < 450) {
      isMobilePortrait = isPortrait;
    }

    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    textMultiplier = blockSizeVertical;
    imageSizeMultiplier = blockSizeHorizontal;
    heightMultiplier = blockSizeVertical;
  }
}

// Extension on double for adding .h and .w suffixes
extension SizeConfigExtensionsDouble on double {
  double get h => this * SizeConfig.blockSizeVertical;
  double get w => this * SizeConfig.blockSizeHorizontal;
}

// Extension on int for adding .h and .w suffixes
extension SizeConfigExtensionsInt on int {
  double get h => this * SizeConfig.blockSizeVertical;
  double get w => this * SizeConfig.blockSizeHorizontal;
}
