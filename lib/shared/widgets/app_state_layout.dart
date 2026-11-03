import 'package:flutter/material.dart';

/// Center short states; keep them reachable on short displays and large text.
class AppStateLayout extends StatelessWidget {
  const AppStateLayout({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) return child;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      );
    },
  );
}
