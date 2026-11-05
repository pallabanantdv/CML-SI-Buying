import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../../core/navigation/app_page_transitions.dart';
import '../../core/navigation/app_transition_config.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
    this.icon,
  });
  final String title;
  final String description;
  final List<Widget> actions;
  final Widget? icon;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> actions,
    Widget? icon,
  }) => showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTransitionConfig.modal,
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        AppPageTransitions.build(
          context,
          animation,
          child,
          transition: AppTransition.scaleFade,
        ),
    pageBuilder: (dialogContext, _, _) => SafeArea(
      child: InheritedTheme.captureAll(
        context,
        AppDialog(
          title: title,
          description: description,
          actions: actions,
          icon: icon,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: AppSpacing.medium),
            ],
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.small),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.large),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: actions,
            ),
          ],
        ),
      ),
    ),
  );
}
