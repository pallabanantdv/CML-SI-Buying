import 'package:flutter/material.dart';

/// For read-only secondary information. Editable required fields remain visible.
class AppExpandableSection extends StatelessWidget {
  const AppExpandableSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      minTileHeight: 48,
      dense: true,
      key: PageStorageKey(title),
      initiallyExpanded: initiallyExpanded,
      maintainState: true,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      children: [child],
    ),
  );
}
