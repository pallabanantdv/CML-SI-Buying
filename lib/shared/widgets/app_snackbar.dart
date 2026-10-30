import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import 'app_svg_icon.dart';

enum AppMessageType { success, error, warning, information }

abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    AppMessageType type = AppMessageType.information,
  }) {
    final color = switch (type) {
      AppMessageType.success => context.appColors.success,
      AppMessageType.error => context.appColors.error,
      AppMessageType.warning => context.appColors.warning,
      AppMessageType.information => context.appColors.info,
    };
    final icon = switch (type) {
      AppMessageType.success => AppIconName.success,
      AppMessageType.error => AppIconName.error,
      AppMessageType.warning => AppIconName.warning,
      AppMessageType.information => AppIconName.info,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              AppSvgIcon(
                icon: icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
        ),
      );
  }
}
