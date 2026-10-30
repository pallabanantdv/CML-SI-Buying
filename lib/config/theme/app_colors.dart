import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF086288);
  static const primaryDark = Color(0xFF06445D);
  static const secondary = Color(0xFF4D8DBA);
  static const highlight = Color(0xFF97D7FF);
  static const accent = Color(0xFFFFEFC4);
  static const canvas = Color(0xFFF3F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF202A34);
  static const textSecondary = Color(0xFF64717D);
  static const border = Color(0xFFD8DEE5);
  static const success = Color(0xFF24734D);
  static const warning = Color(0xFF98620B);
  static const error = Color(0xFFB4232E);
  static const info = secondary;

  static const darkCanvas = Color(0xFF111820);
  static const darkSurface = Color(0xFF1A242E);
  static const darkTextPrimary = Color(0xFFE8EDF2);
  static const darkTextSecondary = Color(0xFFADB9C5);
  static const darkBorder = Color(0xFF34424F);
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.error,
    required this.border,
    required this.textSecondary,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color error;
  final Color border;
  final Color textSecondary;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? error,
    Color? border,
    Color? textSecondary,
  }) => AppSemanticColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    error: error ?? this.error,
    border: border ?? this.border,
    textSecondary: textSecondary ?? this.textSecondary,
  );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      error: Color.lerp(error, other.error, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}

extension AppThemeColors on BuildContext {
  AppSemanticColors get appColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
