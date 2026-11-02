import 'package:flutter/material.dart';

import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_spacing.dart';
import 'app_svg_icon.dart';

/// A compact, flat-color page introduction that follows the application theme.
class AppPageBanner extends StatelessWidget {
  const AppPageBanner({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.eyebrow,
    this.badge,
  });

  final String title;
  final String description;
  final AppIconName icon;
  final String? eyebrow;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppDimensions.cardRadius + 6);

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, scheme.secondary, 0.2)!,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -42,
              child: _CircleDecoration(
                color: scheme.onPrimary.withValues(alpha: 0.07),
                size: 132,
              ),
            ),
            Positioned(
              right: 70,
              bottom: -50,
              child: _CircleDecoration(
                color: scheme.secondary.withValues(alpha: 0.3),
                size: 94,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.cardRadius,
                      ),
                    ),
                    child: AppSvgIcon(
                      icon: icon,
                      size: 23,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow!.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimary.withValues(alpha: 0.78),
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                        ],
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onPrimary.withValues(
                                    alpha: 0.86,
                                  ),
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: AppSpacing.small),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.onPrimary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.small,
                                    vertical: AppSpacing.xSmall,
                                  ),
                                  child: Text(
                                    badge!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleDecoration extends StatelessWidget {
  const _CircleDecoration({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
