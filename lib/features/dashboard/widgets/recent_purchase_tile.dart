import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_card_heading.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../models/dashboard_purchase_model.dart';

class RecentPurchaseTile extends StatelessWidget {
  const RecentPurchaseTile({
    super.key,
    required this.purchase,
    required this.productName,
    required this.currencySymbol,
    this.onTap,
  });
  final DashboardPurchaseModel purchase;
  final String productName;
  final String currencySymbol;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final submitted = purchase.status == DashboardPurchaseStatus.submitted;
    final date = purchase.date;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardHeading(
            title: purchase.number,
            trailing: AppStatusBadge(
              label: submitted ? 'Submitted' : 'Draft',
              color: submitted
                  ? context.appColors.success
                  : context.appColors.warning,
            ),
          ),
          const SizedBox(height: 4),
          Text(productName, style: Theme.of(context).textTheme.titleSmall),
          Text(
            purchase.supplierName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$currencySymbol${AppNumberFormat.amount(purchase.amount)}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
