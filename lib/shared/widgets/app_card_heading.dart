import 'package:flutter/material.dart';

/// A compact title/status row that can grow with long identifiers or text scale.
class AppCardHeading extends StatelessWidget {
  const AppCardHeading({
    super.key,
    required this.title,
    required this.trailing,
  });
  final String title;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final text = Text(title, style: Theme.of(context).textTheme.titleSmall);
      if (constraints.maxWidth < 240 ||
          MediaQuery.textScalerOf(context).scale(14) > 21) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [text, const SizedBox(height: 4), trailing],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: text),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.topRight, child: trailing),
          ),
        ],
      );
    },
  );
}
