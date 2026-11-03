import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../models/dashboard_data.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key, required this.data});
  final DashboardData data;
  @override
  Widget build(BuildContext context) => AppCard(
    tone: AppCardTone.primary,
    title: 'Total purchase value',
    subtitle: data.periodLabel,
    leading: const AppSvgIcon(icon: AppIconName.purchase),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${data.currencySymbol}${AppNumberFormat.amount(data.summary.totalValue)}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${data.summary.transactionCount} purchase transactions',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
