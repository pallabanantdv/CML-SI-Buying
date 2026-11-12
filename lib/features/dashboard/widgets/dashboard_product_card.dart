import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../models/dashboard_product_model.dart';

class DashboardProductCard extends StatelessWidget {
  const DashboardProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.amount,
    required this.currencySymbol,
  });
  final DashboardProductModel product;
  final double quantity;
  final double amount;
  final String currencySymbol;
  @override
  Widget build(BuildContext context) => AppCard(
    title: product.name,
    leading: const AppSvgIcon(icon: AppIconName.inventory),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quantity', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          '${AppNumberFormat.amount(quantity)} ${product.unit}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text('Amount', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          '$currencySymbol${AppNumberFormat.amount(amount)}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ],
    ),
  );
}
