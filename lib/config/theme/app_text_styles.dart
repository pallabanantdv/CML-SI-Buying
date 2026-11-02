import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String titleFontFamily = 'Poppins';
  static const String bodyFontFamily = 'Inter';

  // Retained for compatibility with code that used the former app-wide font.
  static const String fontFamily = bodyFontFamily;

  static TextTheme theme(Brightness brightness) {
    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.darkTextPrimary;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondary
        : AppColors.darkTextSecondary;
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: titleFontFamily,
        color: primary,
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFontFamily,
        color: primary,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFontFamily,
        color: primary,
        fontSize: 13,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFontFamily,
        color: secondary,
        fontSize: 11,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFontFamily,
        color: secondary,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFontFamily,
        color: secondary,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static TextStyle appBarTitle(Brightness brightness) =>
      theme(brightness).titleMedium!.copyWith(fontSize: 15);

  static TextStyle errorText(Brightness brightness) =>
      theme(brightness).bodySmall!.copyWith(color: AppColors.error);
}
