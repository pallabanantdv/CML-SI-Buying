import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../models/point_of_purchase_model.dart';
import '../viewmodels/point_of_purchase_viewmodel.dart';

class PointOfPurchaseScreen extends StatefulWidget {
  const PointOfPurchaseScreen({super.key});

  @override
  State<PointOfPurchaseScreen> createState() => _PointOfPurchaseScreenState();
}

class _PointOfPurchaseScreenState extends State<PointOfPurchaseScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<PointOfPurchaseViewModel>().loadPointOfPurchases());
  }

  @override
  Widget build(BuildContext context) => Consumer<PointOfPurchaseViewModel>(
    builder: (context, viewModel, _) => Scaffold(
      appBar: AppBar(title: Text(viewModel.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.purchaseListMaxWidth,
          ),
          child: _buildContent(context, viewModel),
        ),
      ),
    ),
  );

  Widget _buildContent(
    BuildContext context,
    PointOfPurchaseViewModel viewModel,
  ) {
    if (viewModel.isLoading && viewModel.records.isEmpty) {
      return const AppLoader(label: 'Loading purchase records...');
    }
    if (viewModel.errorMessage != null && viewModel.records.isEmpty) {
      return AppErrorWidget(
        message: viewModel.errorMessage!,
        onRetry: () => unawaited(viewModel.loadPointOfPurchases()),
      );
    }
    if (viewModel.records.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.loadPointOfPurchases,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.pageGutter),
          children: const [
            SizedBox(height: 100),
            AppEmptyState(
              icon: AppIconName.purchase,
              title: 'No purchases found',
              description:
                  'Supplier point-of-purchase records will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadPointOfPurchases,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.pageGutter),
        itemCount: viewModel.records.length + 1,
        separatorBuilder: (_, index) => SizedBox(
          height: index == 0 ? AppSpacing.small : AppSpacing.standard,
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ListHeading(count: viewModel.records.length);
          }
          final record = viewModel.records[index - 1];
          return _PurchaseCard(
            record: record,
            onTap: () => context.pushNamed(
              RouteNames.pointOfPurchaseDetail,
              pathParameters: {'documentName': record.name},
            ),
          );
        },
      ),
    );
  }
}

class _ListHeading extends StatelessWidget {
  const _ListHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supplier purchases', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'Recent point-of-purchase records',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            ),
            child: Text(
              '$count records',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.record, required this.onTap});

  final PointOfPurchaseModel record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supplier = record.supplierName ?? record.supplierId ?? 'Supplier';
    final status = switch (record.docStatus) {
      1 => 'Submitted',
      2 => 'Cancelled',
      _ => 'Draft',
    };
    final statusColor = switch (record.docStatus) {
      1 => theme.extension<AppSemanticColors>()!.success,
      2 => theme.extension<AppSemanticColors>()!.error,
      _ => theme.extension<AppSemanticColors>()!.warning,
    };
    final amount = record.netPayable ?? record.grandTotal;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                ),
                child: AppSvgIcon(
                  icon: AppIconName.purchase,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      record.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              AppStatusBadge(label: status, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.standard),
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.small,
            children: [
              if (record.productType != null)
                _RecordFact(label: 'Product', value: record.productType!),
              if (record.collectionLocation != null)
                _RecordFact(
                  label: 'Collection location',
                  value: record.collectionLocation!,
                ),
              if (record.purchaseDateTime != null)
                _RecordFact(label: 'Date', value: record.purchaseDateTime!),
              if (record.grossWeight != null)
                _RecordFact(
                  label: 'Gross weight',
                  value: '${_number(record.grossWeight!)} kg',
                ),
            ],
          ),
          if (amount != null) ...[
            const SizedBox(height: AppSpacing.standard),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                Text('Net payable', style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(
                  _number(amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.xSmall),
                AppSvgIcon(
                  icon: AppIconName.chevronRight,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordFact extends StatelessWidget {
  const _RecordFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: AppSpacing.xSmall),
      Text(value, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

String _number(double value) => value.toStringAsFixed(2);
