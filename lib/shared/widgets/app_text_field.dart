import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    validator: validator,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textInputAction: TextInputAction.next,
  );
}
