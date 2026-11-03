import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary brand colors - CAML Ocean Blue
  static const primary = Color(0xFF17658A);
  static const primaryDark = Color(0xFF164D66);

  // Secondary brand colors - CAML Green
  static const secondary = Color(0xFF75A843);
  static const secondaryDark = Color(0xFF527D30);

  // Highlight and accent colors
  static const highlight = Color(0xFFA8DCE8);
  static const accent = Color(0xFFE3C53A);
  static const softBlue = Color(0xFF5CA5C4);

  // Light theme background
  static const canvas = Color(0xFFF4F8F9);
  static const surface = Color(0xFFFFFFFF);

  // Light theme text
  static const textPrimary = Color(0xFF203642);
  static const textSecondary = Color(0xFF647984);

  // Borders and dividers
  static const border = Color(0xFFD8E5E8);

  // Semantic colors
  static const success = Color(0xFF46732F);
  static const warning = Color(0xFF825C0B);
  static const error = Color(0xFFB83B42);
  static const info = Color(0xFF216E91);

  // Dark theme backgrounds
  static const darkCanvas = Color(0xFF101E26);
  static const darkSurface = Color(0xFF192D38);

  // Dark theme text
  static const darkTextPrimary = Color(0xFFF0F6F7);
  static const darkTextSecondary = Color(0xFFB1C5CE);

  static const darkSuccess = Color(0xFFA0CF7D);
  static const darkWarning = Color(0xFFE8C675);
  static const darkError = Color(0xFFFFA4A9);
  static const darkInfo = Color(0xFFA8DCE8);

  // Dark theme border
  static const darkBorder = Color(0xFF34505D);
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
