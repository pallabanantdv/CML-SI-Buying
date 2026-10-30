import 'package:flutter/material.dart';

class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
  });

  final T? value;
  final ValueChanged<T?> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      RadioGroup<T>(groupValue: value, onChanged: onChanged, child: child);
}

class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => RadioListTile<T>(
    value: value,
    enabled: enabled,
    title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    contentPadding: EdgeInsets.zero,
    dense: true,
    visualDensity: VisualDensity.compact,
  );
}
