import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_svg_icon.dart';

class AppSummaryCard extends StatelessWidget {
  const AppSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final AppIconName icon;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(value, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(width: 8),
            AppSvgIcon(
              icon: icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
