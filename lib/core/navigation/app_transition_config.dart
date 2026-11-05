import 'package:flutter/material.dart';

abstract final class AppTransitionConfig {
  static const forward = Duration(milliseconds: 280);
  static const back = Duration(milliseconds: 240);
  static const detail = Duration(milliseconds: 300);
  static const bottomNavigation = Duration(milliseconds: 200);
  static const modal = Duration(milliseconds: 220);
  static const authentication = Duration(milliseconds: 350);
  static const splashToHome = Duration(milliseconds: 400);
  static const curve = Curves.easeOutCubic;
  static const reverseCurve = Curves.easeInOutCubic;
  static const slideOffset = Offset(0.10, 0);
  static const initialScale = 0.97;
  static const initialTabOpacity = 0.90;
}
