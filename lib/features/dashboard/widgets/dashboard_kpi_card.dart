import 'package:flutter/material.dart';

import '../../../shared/widgets/app_summary_card.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final int value;
  final AppIconName icon;
  @override
  Widget build(BuildContext context) =>
      AppSummaryCard(label: label, value: '$value', icon: icon);
}
