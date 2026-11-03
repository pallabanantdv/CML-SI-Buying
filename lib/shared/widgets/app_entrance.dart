import 'package:flutter/material.dart';

/// One short entrance per mounted card; no timers, stagger, or repeat animation.
class AppEntrance extends StatelessWidget {
  const AppEntrance({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 5 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
