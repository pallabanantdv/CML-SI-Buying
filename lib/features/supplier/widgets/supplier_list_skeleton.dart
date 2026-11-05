import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton/skeleton.dart';

class SupplierListSkeleton extends StatelessWidget {
  const SupplierListSkeleton({super.key});
  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    label: 'Loading suppliers...',
    child: SkeletonList(
      itemBuilder: (_, _) => const SkeletonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SkeletonText(widthFactor: 0.75, lineHeight: 18),
                ),
                SizedBox(width: 8),
                SkeletonBox(width: 56, height: 24),
              ],
            ),
            SizedBox(height: 2),
            SkeletonText(widthFactor: 0.4, lineHeight: 12),
            SizedBox(height: 4),
            SkeletonText(widthFactor: 0.8, lineHeight: 12),
            SizedBox(height: 6),
            SkeletonText(
              lines: 2,
              widthFactor: 0.65,
              lineHeight: 14,
              spacing: 4,
            ),
          ],
        ),
      ),
    ),
  );
}
