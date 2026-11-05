import 'package:flutter/material.dart';

import '../../../shared/widgets/skeleton/skeleton.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const SkeletonShimmer(
    label: 'Loading profile...',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonCircle(),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    SkeletonText(widthFactor: 0.7, lineHeight: 18),
                    SizedBox(height: 2),
                    SkeletonText(widthFactor: 0.9, lineHeight: 12),
                  ],
                ),
              ),
              SizedBox(width: 4),
              SkeletonBox(width: 56, height: 24),
            ],
          ),
        ),
        SizedBox(height: 8),
        SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonText(widthFactor: 0.6, lineHeight: 18),
              SizedBox(height: 8),
              SkeletonInfoRows(count: 7),
            ],
          ),
        ),
        SizedBox(height: 8),
        SkeletonCard(
          child: Column(
            children: [
              SkeletonText(widthFactor: 0.2),
              SizedBox(height: 8),
              SkeletonBox(height: 30),
            ],
          ),
        ),
      ],
    ),
  );
}
