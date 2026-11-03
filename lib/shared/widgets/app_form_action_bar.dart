import 'package:flutter/material.dart';

import '../../config/theme/app_dimensions.dart';
import 'app_button.dart';

class AppFormActionBar extends StatelessWidget {
  const AppFormActionBar({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.detailContentMaxWidth,
            ),
            child: AppButton(
              label: label,
              isLoading: isLoading,
              onPressed: onPressed,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Validate all mounted fields and bring the first error above the keyboard.
Future<bool> validateAndReveal(GlobalKey<FormState> key) async {
  if (key.currentState!.validate()) return true;
  await WidgetsBinding.instance.endOfFrame;
  final root = key.currentContext;
  if (root == null || !root.mounted) return false;
  BuildContext? firstError;
  void visit(Element element) {
    if (firstError != null) return;
    if (element is StatefulElement &&
        element.state is FormFieldState &&
        (element.state as FormFieldState).hasError) {
      firstError = element;
      return;
    }
    element.visitChildren(visit);
  }

  root.visitChildElements(visit);
  if (firstError != null && firstError!.mounted) {
    await Scrollable.ensureVisible(
      firstError!,
      alignment: 0.1,
      duration: MediaQuery.of(root).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
    );
  }
  return false;
}
