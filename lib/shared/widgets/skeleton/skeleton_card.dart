import 'package:flutter/material.dart';

import '../app_card.dart';
import '../../../config/theme/app_spacing.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => AppCard(padding: padding, child: child);
}
