import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton/skeleton.dart';

class PurchaseDetailSkeleton extends StatelessWidget {
  const PurchaseDetailSkeleton({super.key});
  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    label: 'Loading purchase details...',
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SkeletonText(widthFactor: 0.8, lineHeight: 18),
                  ),
                  SizedBox(width: 8),
                  SkeletonBox(width: 60, height: 24),
                ],
              ),
              SizedBox(height: 4),
              SkeletonText(widthFactor: 0.6, lineHeight: 16),
              SizedBox(height: 8),
              SkeletonText(widthFactor: 0.65, lineHeight: 22),
            ],
          ),
        ),
        for (final count in const [4, 6, 6, 4]) ...[
          const SizedBox(height: 12),
          SkeletonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(widthFactor: 0.6, lineHeight: 18),
                const SizedBox(height: 8),
                SkeletonInfoRows(count: count),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        const SkeletonCard(
          child: Column(
            children: [
              SkeletonText(widthFactor: 0.5, lineHeight: 18),
              SizedBox(height: 8),
              SkeletonInfoRows(count: 3),
            ],
          ),
        ),
      ],
    ),
  );
}
