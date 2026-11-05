import 'package:flutter/material.dart';

import 'skeleton.dart';

/// Matches the application's label/value rows, including narrow-screen stacking.
class SkeletonInfoRows extends StatelessWidget {
  const SkeletonInfoRows({super.key, this.count = 4});
  final int count;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) > 21;
      return Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: stacked
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(widthFactor: 0.35),
                        SizedBox(height: 4),
                        SkeletonText(widthFactor: 0.6),
                      ],
                    )
                  : const Row(
                      children: [
                        Expanded(child: SkeletonText(widthFactor: 0.65)),
                        SizedBox(width: 12),
                        Expanded(child: SkeletonText(widthFactor: 0.8)),
                      ],
                    ),
            ),
        ],
      );
    },
  );
}
