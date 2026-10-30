import 'package:flutter/material.dart';

import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_colors.dart';
import 'app_svg_icon.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger, success }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final AppIconName? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading ? onPressed : null;
    final colors = Theme.of(context).colorScheme;
    final style = switch (variant) {
      AppButtonVariant.primary => null,
      AppButtonVariant.secondary => FilledButton.styleFrom(
        backgroundColor: colors.secondaryContainer,
        foregroundColor: colors.onSecondaryContainer,
      ),
      AppButtonVariant.outlined => OutlinedButton.styleFrom(),
      AppButtonVariant.text => TextButton.styleFrom(),
      AppButtonVariant.danger => FilledButton.styleFrom(
        backgroundColor: context.appColors.error,
        foregroundColor: AppColors.surface,
      ),
      AppButtonVariant.success => FilledButton.styleFrom(
        backgroundColor: context.appColors.success,
        foregroundColor: AppColors.surface,
      ),
    };
    final child = _content(context);
    final button = switch (variant) {
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: enabled,
        style: style,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: enabled,
        style: style,
        child: child,
      ),
      _ => FilledButton(onPressed: enabled, style: style, child: child),
    };
    return Semantics(
      button: true,
      enabled: enabled != null,
      liveRegion: isLoading,
      label: isLoading ? '$label in progress' : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.buttonHeight,
        ),
        child: expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (isLoading) {
      final scheme = Theme.of(context).colorScheme;
      final spinnerColor = switch (variant) {
        AppButtonVariant.outlined || AppButtonVariant.text => scheme.primary,
        AppButtonVariant.secondary => scheme.onSecondaryContainer,
        AppButtonVariant.danger ||
        AppButtonVariant.success ||
        AppButtonVariant.primary => scheme.onPrimary,
      };
      return Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: Opacity(opacity: 0, child: _labelContent(context)),
          ),
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          ),
        ],
      );
    }
    return _labelContent(context);
  }

  Widget _labelContent(BuildContext context) {
    if (icon == null) return Text(label);
    final scheme = Theme.of(context).colorScheme;
    final iconColor = switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.secondary => scheme.onSecondaryContainer,
      AppButtonVariant.outlined || AppButtonVariant.text => scheme.primary,
      AppButtonVariant.danger || AppButtonVariant.success => AppColors.surface,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSvgIcon(icon: icon!, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.small),
        Text(label),
      ],
    );
  }
}
