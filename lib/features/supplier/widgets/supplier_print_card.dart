import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../core/models/html_print_document.dart';
import '../../../core/widgets/html_print_preview_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';

class SupplierPrintCard extends StatelessWidget {
  const SupplierPrintCard({
    super.key,
    required this.onPreview,
    this.loading = false,
    this.error,
    this.document,
    this.onRetry,
  });
  final HtmlPrintDocument? document;
  final VoidCallback? onRetry;
  final VoidCallback? onPreview;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) => AppCard(
    title: 'Supplier card',
    subtitle: 'Card front 2',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (document != null) ...[
          SizedBox(
            height: 380,
            child: HtmlPrintPreviewScreen(
              key: ObjectKey(document),
              embedded: true,
              htmlContent: document!.html,
              title: document!.title,
              baseUrl: document!.baseUrl,
              documentId: document!.documentId,
              cookies: document!.cookies,
              loadPdf: document!.loadPdf,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (loading) ...[
          const SkeletonShimmer(
            label: 'Loading supplier print format...',
            child: SkeletonBox(height: 80),
          ),
          const SizedBox(height: 12),
        ],
        if (error != null) ...[
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        AppButton(
          label: error == null ? 'Print Preview' : 'Retry Print Preview',
          isLoading: loading,
          onPressed: error != null ? onRetry : onPreview,
        ),
      ],
    ),
  );
}
