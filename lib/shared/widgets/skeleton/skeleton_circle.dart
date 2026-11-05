import 'package:flutter/material.dart';

import 'skeleton_box.dart';

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.diameter = 40});
  final double diameter;
  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: diameter, height: diameter, shape: BoxShape.circle);
}
