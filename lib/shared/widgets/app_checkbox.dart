import 'package:flutter/material.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.enabled = true,
  });
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: value,
    onChanged: enabled ? onChanged : null,
    title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    dense: true,
    visualDensity: VisualDensity.compact,
  );
}
