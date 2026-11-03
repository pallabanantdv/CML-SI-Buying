import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_card_heading.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_entrance.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../models/point_of_purchase_model.dart';

class AppPurchaseCard extends StatelessWidget {
  const AppPurchaseCard({super.key, required this.record, required this.onTap});
  final PointOfPurchaseModel record;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = switch (record.docStatus) {
      1 => 'Submitted',
      2 => 'Cancelled',
      _ => 'Draft',
    };
    final color = switch (record.docStatus) {
      1 => context.appColors.success,
      2 => context.appColors.error,
      _ => context.appColors.warning,
    };
    final amount = record.netPayable ?? record.grandTotal;
    final date = DateTime.tryParse(record.purchaseDateTime ?? '');
    final supplier = record.supplierName ?? record.supplierId ?? 'Supplier';
    final facts = [
      record.productType,
      record.collectionLocation,
      if (record.grossWeight != null)
        '${record.grossWeight!.toStringAsFixed(2)} kg',
    ].whereType<String>().join(' \u00b7 ');
    return AppEntrance(
      child: AppCard(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCardHeading(
              title: record.name,
              trailing: AppStatusBadge(label: status, color: color),
            ),
            const SizedBox(height: AppSpacing.relatedGap),
            Tooltip(
              message: supplier,
              child: Text(
                supplier,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 2),
              Tooltip(
                message: facts,
                child: Text(
                  facts,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            if (record.purchaseDateTime != null || amount != null) ...[
              const SizedBox(height: AppSpacing.small),
              LayoutBuilder(
                builder: (context, constraints) {
                  final dateWidget = Text(
                    date == null
                        ? record.purchaseDateTime ?? ''
                        : AppDateUtils.shortDate(date),
                    style: theme.textTheme.bodySmall,
                  );
                  final amountWidget = Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Net: ',
                          style: theme.textTheme.bodySmall,
                        ),
                        TextSpan(
                          text: amount == null
                              ? ''
                              : AppNumberFormat.amount(amount),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                  if (constraints.maxWidth >= 310 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 18 &&
                      amount != null &&
                      record.purchaseDateTime != null) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        dateWidget,
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: amountWidget,
                          ),
                        ),
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (record.purchaseDateTime != null) dateWidget,
                      if (amount != null) amountWidget,
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
