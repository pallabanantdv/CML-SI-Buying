import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import 'app_button.dart';
import 'app_svg_icon.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              icon: AppIconName.cloudOff,
              size: 28,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.medium),
              AppButton(
                label: 'Try again',
                onPressed: onRetry,
                variant: AppButtonVariant.outlined,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
