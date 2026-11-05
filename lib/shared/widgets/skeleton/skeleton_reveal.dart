import 'package:flutter/material.dart';

/// Drops the loading tree immediately and fades in the terminal state.
/// Keeps the child mounted during refresh and respects reduced motion.
class SkeletonReveal extends StatelessWidget {
  const SkeletonReveal({super.key, required this.loading, required this.child});
  final bool loading;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(loading),
    tween: Tween(begin: loading ? 1 : 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240),
    builder: (_, value, child) => Opacity(opacity: value, child: child),
    child: child,
  );
}
