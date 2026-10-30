import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_dimensions.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.standard),
    this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final leadingWidgets = leading == null
        ? null
        : <Widget>[leading!, const SizedBox(width: AppSpacing.small)];
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || leading != null || trailing != null)
            Row(
              children: [
                ...?leadingWidgets,
                if (title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          if (child != null) ...[
            if (title != null || leading != null || trailing != null)
              const SizedBox(height: AppSpacing.medium),
            child!,
          ],
        ],
      ),
    );
    final card = Card(child: content);
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: card,
      ),
    );
  }
}
