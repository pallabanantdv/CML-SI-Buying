import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import 'app_svg_icon.dart';

/// Lightweight introduction for forms and the component showcase.
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        Text(eyebrow!, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.small),
      ],
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.small),
      Text(description, style: Theme.of(context).textTheme.bodyMedium),
      if (badge != null) ...[
        const SizedBox(height: 8),
        Text(badge!, style: Theme.of(context).textTheme.labelMedium),
      ],
    ],
  );
}
