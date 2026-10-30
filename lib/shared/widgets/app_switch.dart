import 'package:flutter/material.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.enabled = true,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    value: value,
    onChanged: enabled ? onChanged : null,
    title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}
