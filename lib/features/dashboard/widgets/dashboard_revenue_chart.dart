import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../config/theme/app_colors.dart';
import '../models/revenue_summary.dart';

class DashboardRevenueChart extends StatelessWidget {
  const DashboardRevenueChart({super.key, this.revenue});
  final RevenueSummary? revenue;

  static const _colors = [
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFD97706),
    Color(0xFF9333EA),
  ];

  @override
  Widget build(BuildContext context) {
    final data = revenue;
    if (data == null) {
      return const AppCard(
        title: 'Revenue trend',
        child: Text('Revenue could not be loaded. Pull down to retry.'),
      );
    }
    final quarters = [for (final row in data.quarters) row.$1];
    final values = [for (final row in data.quarters) row.$2];
    final total = data.total;
    final positiveTotal = values.fold<double>(
      0,
      (sum, value) => sum + math.max(0, value),
    );
    final theme = Theme.of(context);
    return AppCard(
      title: 'Revenue trend',
      // subtitle: '${data.fromDate} – ${data.toDate}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${data.currency} ${AppNumberFormat.amount(total)}',
            style: theme.textTheme.titleLarge,
          ),
          Text('Total revenue', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          if (positiveTotal <= 0)
            const Text('No positive revenue in this period.')
          else
            Center(
              child: SizedBox.square(
                dimension: 220,
                child: Semantics(
                  image: true,
                  label: data.quarters
                      .map(
                        (row) =>
                            '${row.$1}: ${data.currency} ${AppNumberFormat.amount(row.$2)}',
                      )
                      .join(', '),
                  child: _InteractiveRevenuePie(revenue: data, colors: _colors),
                ),
              ),
            ),
          const SizedBox(height: 20),
          for (var index = 0; index < quarters.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colors[index % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(quarters[index])),
                  Flexible(
                    flex: 2,
                    child: Text(
                      '${data.currency} ${AppNumberFormat.amount(values[index])} · '
                      '${(positiveTotal <= 0 ? 0 : math.max(0, values[index]) / positiveTotal * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InteractiveRevenuePie extends StatefulWidget {
  const _InteractiveRevenuePie({required this.revenue, required this.colors});
  final RevenueSummary revenue;
  final List<Color> colors;

  @override
  State<_InteractiveRevenuePie> createState() => _InteractiveRevenuePieState();
}

class _InteractiveRevenuePieState extends State<_InteractiveRevenuePie> {
  final _tooltip = GlobalKey<TooltipState>();
  String _message = '';

  void _showValue(Offset position, Size size) {
    final delta = position - size.center(Offset.zero);
    if (delta.distance > math.min(size.width, size.height) / 2 - 2) return;
    final quarters = widget.revenue.quarters;
    final total = quarters.fold<double>(
      0,
      (sum, row) => sum + math.max(0, row.$2),
    );
    if (total <= 0) return;
    final angle =
        (math.atan2(delta.dy, delta.dx) + math.pi / 2) % (2 * math.pi);
    var end = 0.0;
    for (final row in quarters) {
      end += math.max(0, row.$2) / total * 2 * math.pi;
      if (angle < end) {
        setState(
          () => _message =
              '${row.$1}: ${widget.revenue.currency} ${AppNumberFormat.amount(row.$2)}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tooltip.currentState?.ensureTooltipVisible();
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => Tooltip(
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(4),
        ),
        key: _tooltip,
        message: _message,
        triggerMode: TooltipTriggerMode.manual,
        showDuration: const Duration(seconds: 3),
        child: MouseRegion(
          onHover: (event) =>
              _showValue(event.localPosition, constraints.biggest),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) =>
                _showValue(details.localPosition, constraints.biggest),
            child: CustomPaint(
              painter: _RevenuePiePainter(
                values: [
                  for (final row in widget.revenue.quarters)
                    math.max(0.0, row.$2),
                ],
                colors: widget.colors,
                separator: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenuePiePainter extends CustomPainter {
  const _RevenuePiePainter({
    required this.values,
    required this.colors,
    required this.separator,
  });

  final List<double> values;
  final List<Color> colors;
  final Color separator;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    final radius = math.min(size.width, size.height) / 2 - 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final border = Paint()
      ..color = separator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..color = colors[index % colors.length],
      );
      canvas.drawArc(rect, start, sweep, true, border);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RevenuePiePainter oldDelegate) =>
      oldDelegate.separator != separator ||
      oldDelegate.values != values ||
      oldDelegate.colors != colors;
}
