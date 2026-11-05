import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton/skeleton.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    label: 'Loading purchase overview...',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 36, height: 36),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonText(lines: 2, widthFactor: 0.55)),
                ],
              ),
              SizedBox(height: 8),
              SkeletonText(widthFactor: 0.55, lineHeight: 28),
              SizedBox(height: 4),
              SkeletonText(widthFactor: 0.55, lineHeight: 12),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const _Pair(height: 26),
        const SizedBox(height: 12),
        const SkeletonText(widthFactor: 0.3, lineHeight: 18),
        const SizedBox(height: 8),
        const _Pair(height: 48),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: SkeletonText(widthFactor: 0.45, lineHeight: 18),
        ),
        SkeletonList(
          itemCount: 3,
          itemBuilder: (_, _) => const SkeletonCard(
            child: Column(
              children: [
                SkeletonText(widthFactor: 0.8, lineHeight: 18),
                SizedBox(height: 4),
                SkeletonText(widthFactor: 0.6),
                SizedBox(height: 8),
                SkeletonText(widthFactor: 0.8),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Pair extends StatelessWidget {
  const _Pair({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(14) <= 21
          ? 2
          : 1;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 2; i++)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 8) / columns,
              child: SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonText(widthFactor: 0.75),
                    const SizedBox(height: 8),
                    SkeletonBox(height: height, width: 70),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
