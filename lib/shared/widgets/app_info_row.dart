import 'package:flutter/material.dart';

/// Read-only facts use one row when space permits; large text keeps full values.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
  });
  final String label;
  final String value;
  final bool selectable;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final labelWidget = Text(label, style: theme.textTheme.bodySmall);
      final valueText = Text(value, style: theme.textTheme.bodyMedium);
      // Read-only values do not need SelectableText's globally keyed
      // EditableText subtree, which can be reparented during section toggles.
      final valueWidget = selectable
          ? SelectionArea(child: valueText)
          : valueText;
      if (constraints.maxWidth < 240 ||
          MediaQuery.textScalerOf(context).scale(14) > 21) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWidget, const SizedBox(height: 2), valueWidget],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: labelWidget),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: valueWidget),
        ],
      );
    },
  );
}

class AppInfoGrid extends StatelessWidget {
  const AppInfoGrid({super.key, required this.fields});
  final List<(String, String)> fields;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 520 &&
              MediaQuery.textScalerOf(context).scale(14) <= 18
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final field in fields)
            SizedBox(
              width: width,
              child: AppInfoRow(label: field.$1, value: field.$2),
            ),
        ],
      );
    },
  );
}
