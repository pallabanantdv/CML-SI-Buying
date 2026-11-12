import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../models/dashboard_data.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    super.key,
    required this.data,
    this.dateRange,
    this.onSelectDateRange,
    this.onClearDateRange,
  });
  final DashboardData data;
  final DateTimeRange? dateRange;
  final VoidCallback? onSelectDateRange;
  final VoidCallback? onClearDateRange;
  @override
  Widget build(BuildContext context) => AppCard(
    tone: AppCardTone.primary,
    title: 'Total purchase value',
    subtitle: data.periodLabel,
    leading: const AppSvgIcon(icon: AppIconName.purchase),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onSelectDateRange != null) ...[
          InkWell(
            onTap: onSelectDateRange,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date range',
                suffixIcon: dateRange == null
                    ? const Icon(Icons.date_range_outlined)
                    : IconButton(
                        tooltip: 'Reset date range',
                        onPressed: onClearDateRange,
                        icon: const Icon(Icons.clear),
                      ),
              ),
              child: Text(data.periodLabel),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Purchase amount', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          '${data.currencySymbol}${AppNumberFormat.amount(data.summary.totalValue)}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Purchase transactions',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 2),
        Text(
          '${data.summary.transactionCount}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
