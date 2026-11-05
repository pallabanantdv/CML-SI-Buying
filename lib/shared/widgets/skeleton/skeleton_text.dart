import 'package:flutter/material.dart';

import 'skeleton_box.dart';

class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.lines = 1,
    this.widthFactor = 1,
    this.lineHeight = 14,
    this.spacing = 6,
  });
  final int lines;
  final double widthFactor;
  final double lineHeight;
  final double spacing;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < lines; i++) ...[
        if (i > 0) SizedBox(height: spacing),
        FractionallySizedBox(
          widthFactor: i == lines - 1 ? widthFactor : 1,
          child: SkeletonBox(
            height:
                lineHeight * MediaQuery.textScalerOf(context).scale(14) / 14,
          ),
        ),
      ],
    ],
  );
}
