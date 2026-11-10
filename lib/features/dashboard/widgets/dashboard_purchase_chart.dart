import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../config/theme/app_colors.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../models/purchase_invoice_summary.dart';

enum _ChartPeriod { week, month, year }

class DashboardPurchaseChart extends StatefulWidget {
  const DashboardPurchaseChart({super.key, this.summary});
  final PurchaseInvoiceSummary? summary;

  @override
  State<DashboardPurchaseChart> createState() => _DashboardPurchaseChartState();
}

class _DashboardPurchaseChartState extends State<DashboardPurchaseChart> {
  _ChartPeriod _period = _ChartPeriod.month;

  String? _selectedWeek;

  PurchaseTrend? get _week {
    final weeks = widget.summary?.weekly ?? [];
    return weeks.where((week) => week.id == _selectedWeek).firstOrNull ??
        weeks.lastOrNull;
  }

  List<(String, double, double)> get _series => switch (_period) {
    _ChartPeriod.week => _week?.dailyCounts ?? [],
    _ChartPeriod.month => [
      for (final row in widget.summary?.monthly ?? <PurchaseTrend>[])
        (row.label, row.count, row.amount),
    ],
    _ChartPeriod.year => [
      for (final row in widget.summary?.yearly ?? <PurchaseTrend>[])
        (row.label, row.count, row.amount),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final series = _series;
    final maximum = series.fold<double>(
      0,
      (max, row) => row.$2 > max ? row.$2 : max,
    );
    final total = series.fold<double>(0, (sum, row) => sum + row.$2);
    final theme = Theme.of(context);
    String tooltip((String, double, double) row) =>
        '${row.$1}: ${row.$2.toInt()} transactions\n'
        'Amount: ${widget.summary?.currency ?? ''} ${AppNumberFormat.amount(row.$3)}';
    return AppCard(
      title: 'Purchase trends',
      subtitle: 'Purchase invoice counts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final period in _ChartPeriod.values)
                ChoiceChip(
                  label: Text(switch (period) {
                    _ChartPeriod.week => 'Week',
                    _ChartPeriod.month => 'Month',
                    _ChartPeriod.year => 'Year',
                  }),
                  selected: _period == period,
                  onSelected: (_) => setState(() => _period = period),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${total.toInt()} transactions',
            style: theme.textTheme.titleLarge,
          ),
          if (_period == _ChartPeriod.week && _week != null) ...[
            const SizedBox(height: 12),
            AppDropdown<String>(
              value: _week!.id,
              label: 'Week',
              items: [
                for (final week in widget.summary!.weekly)
                  DropdownMenuItem(value: week.id, child: Text(week.label)),
              ],
              onChanged: (value) => setState(() => _selectedWeek = value),
            ),
          ],
          if (series.isEmpty)
            const Text('No purchase trend data for this period.'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  (constraints.maxWidth / (series.isEmpty ? 1 : series.length))
                      .clamp(48.0, 88.0);
              String axisLabel(String label) => _period == _ChartPeriod.month
                  ? label.trim().replaceFirst(RegExp(r'\s+(?=\d{4}$)'), '\n')
                  : label;
              var labelHeight = 0.0;
              for (final row in series) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: axisLabel(row.$1),
                    style: theme.textTheme.bodySmall,
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  textAlign: TextAlign.center,
                )..layout(maxWidth: width - 8);
                if (painter.height > labelHeight) labelHeight = painter.height;
                painter.dispose();
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final row in series)
                      SizedBox(
                        width: width,
                        child: Semantics(
                          label: tooltip(row),
                          child: Tooltip(
                            textStyle: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            triggerMode: TooltipTriggerMode.tap,
                            message: tooltip(row),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 160,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      width: 24,
                                      height: maximum <= 0
                                          ? 0
                                          : 160 * row.$2 / maximum,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: labelHeight,
                                  width: width,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      axisLabel(row.$1),
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
