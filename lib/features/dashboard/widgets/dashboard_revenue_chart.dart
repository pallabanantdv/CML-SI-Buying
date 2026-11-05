import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_card.dart';

/// Fixed quarterly revenue examples, independent of dashboard API data.
class DashboardRevenueChart extends StatelessWidget {
  const DashboardRevenueChart({super.key});

  static const _quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
  static const _values = [18000.0, 24000.0, 27000.0, 31000.0];
  static const _colors = [
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFD97706),
    Color(0xFF9333EA),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _values.fold<double>(0, (sum, value) => sum + value);
    final theme = Theme.of(context);
    return AppCard(
      title: 'Revenue trend',
      subtitle: 'Static sample revenue by quarter · 2026',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '\$${AppNumberFormat.amount(total)}',
            style: theme.textTheme.titleLarge,
          ),
          Text('Total revenue', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          Center(
            child: SizedBox.square(
              dimension: 220,
              child: Semantics(
                image: true,
                label: 'Revenue share: Q1 18%, Q2 24%, Q3 27%, Q4 31%.',
                child: CustomPaint(
                  painter: _RevenuePiePainter(
                    values: _values,
                    colors: _colors,
                    separator: theme.colorScheme.surface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < _quarters.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_quarters[index])),
                  Flexible(
                    flex: 2,
                    child: Text(
                      '\$${AppNumberFormat.amount(_values[index])} · '
                      '${(_values[index] / total * 100).toStringAsFixed(0)}%',
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
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[index]);
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
