import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';

/// A bounded number of placeholders; the parent retains ownership of scrolling.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 4,
    this.spacing = AppSpacing.cardGap,
  });
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final double spacing;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < itemCount; i++) ...[
        if (i > 0) SizedBox(height: spacing),
        itemBuilder(context, i),
      ],
    ],
  );
}
