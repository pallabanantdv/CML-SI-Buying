import 'package:flutter/material.dart';

/// Concise screen title used alongside the shared header's brand mark.
class AppHeaderTitle extends StatelessWidget {
  const AppHeaderTitle({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis);
}
