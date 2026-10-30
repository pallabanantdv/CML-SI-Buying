import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const fontFamily = 'Inter';

  static TextTheme theme(Brightness brightness) {
    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.darkTextPrimary;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondary
        : AppColors.darkTextSecondary;
    return TextTheme(
      displayLarge: TextStyle(
        color: primary,
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        color: primary,
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        color: primary,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        color: primary,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: primary,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: primary, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: primary, fontSize: 14, height: 1.45),
      bodySmall: TextStyle(color: secondary, fontSize: 12, height: 1.4),
      labelLarge: const TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: secondary,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w400,
      ),
    ).apply(fontFamily: fontFamily);
  }

  static TextStyle appBarTitle(Brightness brightness) =>
      theme(brightness).titleMedium!.copyWith(fontSize: 16);

  static TextStyle errorText(Brightness brightness) =>
      theme(brightness).bodySmall!.copyWith(color: AppColors.error);
}
