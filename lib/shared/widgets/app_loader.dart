import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      label: label ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.medium),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    ),
  );
}
