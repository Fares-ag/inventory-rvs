import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  static double getCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (isMobile(context)) return width - 32;
    if (isTablet(context)) return (width - 48) / 2;
    return (width - 96) / 3;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final padding = getPadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getHorizontalPadding(BuildContext context) {
    final padding = getPadding(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) return 48.0;
    return 52.0;
  }

  static double getIconSize(BuildContext context) {
    if (isMobile(context)) return 20.0;
    return 24.0;
  }

  static double getFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize * 1.2;
  }
}


