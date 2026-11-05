import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_card.dart';

enum _ChartPeriod { week, month, year }

/// Local sample series only; selecting a period never requests server data.
class DashboardPurchaseChart extends StatefulWidget {
  const DashboardPurchaseChart({super.key});

  @override
  State<DashboardPurchaseChart> createState() => _DashboardPurchaseChartState();
}

class _DashboardPurchaseChartState extends State<DashboardPurchaseChart> {
  _ChartPeriod _period = _ChartPeriod.month;

  List<(String, double)> get _series => switch (_period) {
    _ChartPeriod.week => const [
      ('Mon', 3200),
      ('Tue', 4500),
      ('Wed', 2800),
      ('Thu', 5100),
      ('Fri', 3900),
      ('Sat', 2400),
      ('Sun', 1600),
    ],
    _ChartPeriod.month => const [
      ('Jan', 18000),
      ('Feb', 22000),
      ('Mar', 19500),
      ('Apr', 26000),
      ('May', 24000),
      ('Jun', 28500),
      ('Jul', 31000),
      ('Aug', 27500),
      ('Sep', 33000),
      ('Oct', 35000),
      ('Nov', 29000),
      ('Dec', 38000),
    ],
    _ChartPeriod.year => const [
      ('2022', 180000),
      ('2023', 225000),
      ('2024', 265000),
      ('2025', 310000),
      ('2026', 351500),
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
    return AppCard(
      title: 'Purchase trends',
      subtitle: 'Static sample data · Purchase value (\$)',
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
            '\$${AppNumberFormat.amount(total)}',
            style: theme.textTheme.titleLarge,
          ),
          Text(switch (_period) {
            _ChartPeriod.week => 'Sample week · Monday–Sunday',
            _ChartPeriod.month => 'Sample year · January–December',
            _ChartPeriod.year => 'Sample years · 2022–2026',
          }, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth / series.length).clamp(
                48.0,
                88.0,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final row in series)
                      SizedBox(
                        width: width,
                        child: Semantics(
                          label:
                              '${row.$1}: ${AppNumberFormat.amount(row.$2)} dollars',
                          child: Tooltip(
                            message:
                                '${row.$1}: \$${AppNumberFormat.amount(row.$2)}',
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
                                      height: 160 * row.$2 / maximum,
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
                                Text(row.$1, style: theme.textTheme.bodySmall),
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
