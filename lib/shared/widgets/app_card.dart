import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_spacing.dart';

/// Semantic tone of a card. Drives the accent bar and leading badge color.
enum AppCardTone { neutral, primary, success, warning, error, info }

/// Flat (2D) card: no elevation, a subtle border, a tinted icon badge and an
/// optional accent bar. All colors come from the theme / [AppSemanticColors].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.child,
    this.tone = AppCardTone.neutral,
    this.showAccentBar = false,
    this.showChevron = true,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  /// Color meaning of the card (badge tint + accent bar).
  final AppCardTone tone;

  /// Shows a thin colored bar on the leading edge of the card.
  final bool showAccentBar;

  /// Shows a chevron when [onTap] is set and no [trailing] is provided.
  final bool showChevron;

  Color _toneColor(ColorScheme scheme, AppSemanticColors colors) {
    switch (tone) {
      case AppCardTone.neutral:
      case AppCardTone.primary:
        return scheme.primary;
      case AppCardTone.success:
        return colors.success;
      case AppCardTone.warning:
        return colors.warning;
      case AppCardTone.error:
        return colors.error;
      case AppCardTone.info:
        return colors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.appColors;
    final toneColor = _toneColor(scheme, colors);
    final radius = BorderRadius.circular(AppDimensions.cardRadius);

    final hasHeader =
        title != null ||
        subtitle != null ||
        leading != null ||
        trailing != null;
    final effectiveTrailing =
        trailing ??
        (onTap != null && showChevron && child == null
            ? Icon(Icons.chevron_right_rounded, color: colors.textSecondary)
            : null);

    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasHeader)
            Row(
              children: [
                if (leading != null) ...[
                  _LeadingBadge(color: toneColor, child: leading!),
                  const SizedBox(width: AppSpacing.small),
                ],
                if (title != null || subtitle != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        if (subtitle != null) ...[
                          if (title != null) const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (effectiveTrailing != null) ...[
                  const SizedBox(width: AppSpacing.small),
                  effectiveTrailing,
                ],
              ],
            ),
          if (child != null) ...[
            if (hasHeader) ...[const SizedBox(height: AppSpacing.small)],
            child!,
          ],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      container: true,
      child: Material(
        color: scheme.surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: toneColor.withValues(alpha: 0.08),
          highlightColor: toneColor.withValues(alpha: 0.04),
          child: showAccentBar
              ? Stack(
                  children: [
                    content,
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: ColoredBox(color: toneColor),
                    ),
                  ],
                )
              : content,
        ),
      ),
    );
  }
}

/// Rounded square with a soft tinted background; recolors icons inside it.
class _LeadingBadge extends StatelessWidget {
  const _LeadingBadge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: 18),
        child: child,
      ),
    );
  }
}
