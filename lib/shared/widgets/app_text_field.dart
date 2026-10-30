import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_svg_icon.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.focusNode,
    this.hint,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.required = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;
  final bool required;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText = widget.obscureText || widget.isPassword;

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText ||
        oldWidget.isPassword != widget.isPassword) {
      _obscureText = widget.obscureText || widget.isPassword;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      fillColor: widget.enabled
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      label: widget.required
          ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: widget.label),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            )
          : null,
      labelText: widget.required ? null : widget.label,
      hintText: widget.hint,
      helperText: widget.helperText,
      prefixIcon: widget.prefixIcon == null
          ? null
          : SizedBox.square(
              dimension: 20,
              child: FittedBox(fit: BoxFit.scaleDown, child: widget.prefixIcon),
            ),
      suffixIcon: widget.isPassword
          ? IconButton(
              tooltip: _obscureText ? 'Show password' : 'Hide password',
              onPressed: widget.enabled
                  ? () => setState(() => _obscureText = !_obscureText)
                  : null,
              icon: AppSvgIcon(
                icon: _obscureText
                    ? AppIconName.visibility
                    : AppIconName.visibilityOff,
              ),
            )
          : widget.suffixIcon,
    );

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: decoration,
      validator: widget.validator,
      obscureText: _obscureText,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      keyboardType: widget.isPassword
          ? TextInputType.visiblePassword
          : widget.keyboardType,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction ?? TextInputAction.next,
      autofillHints: widget.autofillHints,
    );
  }
}
