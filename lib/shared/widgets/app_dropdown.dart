import 'package:flutter/material.dart';

import '../../config/theme/app_dimensions.dart';
import 'app_svg_icon.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.validator,
    this.enabled = true,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String label;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? hint;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    items: items,
    onChanged: enabled ? onChanged : null,
    validator: validator,
    decoration: InputDecoration(labelText: label, hintText: hint),
    icon: const AppSvgIcon(icon: AppIconName.expandMore),
    menuMaxHeight: 320,
    borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
  );
}
