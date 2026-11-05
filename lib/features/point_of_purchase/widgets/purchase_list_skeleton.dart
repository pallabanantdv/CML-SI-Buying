import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton/skeleton.dart';

class PurchaseListSkeleton extends StatelessWidget {
  const PurchaseListSkeleton({super.key});
  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    label: 'Loading purchase records...',
    child: SkeletonList(
      itemBuilder: (_, _) => const SkeletonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: SkeletonText(widthFactor: 0.8, lineHeight: 18)),
                SizedBox(width: 8),
                SkeletonBox(width: 60, height: 24),
              ],
            ),
            SizedBox(height: 4),
            SkeletonText(widthFactor: 0.65, lineHeight: 16),
            SizedBox(height: 2),
            SkeletonText(widthFactor: 0.85, lineHeight: 12),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: SkeletonText(widthFactor: 0.5, lineHeight: 12)),
                Expanded(child: SkeletonText(widthFactor: 0.7, lineHeight: 16)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
