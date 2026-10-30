import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.surface,
          primaryContainer: AppColors.highlight,
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.secondary,
          onSecondary: AppColors.surface,
          secondaryContainer: AppColors.accent,
          onSecondaryContainer: AppColors.textPrimary,
          tertiary: AppColors.highlight,
          onTertiary: AppColors.primaryDark,
          tertiaryContainer: AppColors.accent,
          onTertiaryContainer: AppColors.textPrimary,
          error: AppColors.error,
          surface: isLight ? AppColors.surface : AppColors.darkSurface,
          onSurface: isLight
              ? AppColors.textPrimary
              : AppColors.darkTextPrimary,
        );
    final borderColor = isLight ? AppColors.border : AppColors.darkBorder;
    final textSecondary = isLight
        ? AppColors.textSecondary
        : AppColors.darkTextSecondary;
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
      borderSide: BorderSide(color: borderColor),
    );
    final textTheme = AppTextStyles.theme(brightness);

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight
          ? AppColors.canvas
          : AppColors.darkCanvas,
      extensions: [
        AppSemanticColors(
          success: AppColors.success,
          warning: AppColors.warning,
          info: AppColors.info,
          error: AppColors.error,
          border: borderColor,
          textSecondary: textSecondary,
        ),
      ],
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isLight ? AppColors.surface : AppColors.darkSurface,
        constraints: const BoxConstraints(minHeight: AppDimensions.fieldHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.medium,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        helperStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        errorStyle: AppTextStyles.errorText(brightness).copyWith(height: 1.25),
        enabledBorder: outline,
        border: outline,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: outline,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          textStyle: textTheme.labelLarge!,
          background: AppColors.primary,
          foreground: AppColors.surface,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          textStyle: textTheme.labelLarge!,
          foreground: scheme.primary,
          side: BorderSide(color: borderColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(
          textStyle: textTheme.labelLarge!,
          foreground: scheme.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: BorderSide(color: borderColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.appBarTitle(brightness),
        shape: Border(bottom: BorderSide(color: borderColor)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.dialogRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : textSecondary,
            size: selected ? 23 : 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium!.copyWith(
            color: selected ? scheme.primary : textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium!.copyWith(
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium!.copyWith(
          color: textSecondary,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll(scheme.primary),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppColors.primaryDark
            : AppColors.darkSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.checkboxRadius),
        ),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ButtonStyle _buttonStyle({
    required TextStyle textStyle,
    Color? background,
    Color? foreground,
    BorderSide? side,
  }) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(
      Size(0, AppDimensions.buttonHeight),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.standard),
    ),
    textStyle: WidgetStatePropertyAll(textStyle),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
    ),
    backgroundColor: background == null
        ? null
        : WidgetStatePropertyAll(background),
    foregroundColor: foreground == null
        ? null
        : WidgetStatePropertyAll(foreground),
    side: side == null ? null : WidgetStatePropertyAll(side),
    animationDuration: const Duration(milliseconds: 120),
  );
}
