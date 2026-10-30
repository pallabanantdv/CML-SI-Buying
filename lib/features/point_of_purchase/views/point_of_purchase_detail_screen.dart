import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../viewmodels/point_of_purchase_viewmodel.dart';

class PointOfPurchaseDetailScreen extends StatefulWidget {
  const PointOfPurchaseDetailScreen({super.key, required this.documentName});

  final String documentName;

  @override
  State<PointOfPurchaseDetailScreen> createState() =>
      _PointOfPurchaseDetailScreenState();
}

class _PointOfPurchaseDetailScreenState
    extends State<PointOfPurchaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<PointOfPurchaseViewModel>().loadPointOfPurchase(
        widget.documentName,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PointOfPurchaseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentName != widget.documentName) {
      unawaited(
        context.read<PointOfPurchaseViewModel>().loadPointOfPurchase(
          widget.documentName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<PointOfPurchaseViewModel>(
    builder: (context, viewModel, _) => Scaffold(
      appBar: AppBar(title: const Text('Purchase details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.detailContentMaxWidth,
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
    if (viewModel.isLoadingDetail ||
        viewModel.selectedName != widget.documentName) {
      return const AppLoader(label: 'Loading purchase details...');
    }
    if (viewModel.detailErrorMessage != null) {
      return AppErrorWidget(
        message: viewModel.detailErrorMessage!,
        onRetry: () =>
            unawaited(viewModel.loadPointOfPurchase(widget.documentName)),
      );
    }
    final record = viewModel.selectedRecord;
    if (record == null) {
      return const AppLoader(label: 'Loading purchase details...');
    }

    final displayedFields = <String>{
      'supplier_name1',
      'supplier_name',
      'net_payable',
      'name',
      'docstatus',
      for (final section in _detailSections) ...section.$2,
    };
    final scalarFields = record.entries
        .where(
          (entry) =>
              entry.value is! List &&
              !displayedFields.contains(entry.key) &&
              _hasDetailValue(entry.value),
        )
        .toList();
    final childTables = record.entries
        .where((entry) => entry.value is List)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pageGutter),
      children: [
        _OverviewCard(record: record),
        const SizedBox(height: AppSpacing.standard),
        for (final section in _detailSections) ...[
          _DetailSection(record: record, title: section.$1, fields: section.$2),
          const SizedBox(height: AppSpacing.standard),
        ],
        if (scalarFields.isNotEmpty) ...[
          _DynamicDetailSection(
            title: 'Additional record details',
            fields: scalarFields,
          ),
          const SizedBox(height: AppSpacing.standard),
        ],
        for (final table in childTables) ...[
          _ChildTableSection(name: table.key, rows: table.value as List),
          const SizedBox(height: AppSpacing.standard),
        ],
      ],
    );
  }
}

class _DynamicDetailSection extends StatelessWidget {
  const _DynamicDetailSection({required this.title, required this.fields});

  final String title;
  final List<MapEntry<String, dynamic>> fields;

  @override
  Widget build(BuildContext context) => AppCard(
    title: title,
    child: Column(
      children: [
        for (var index = 0; index < fields.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.medium),
          _DetailRow(
            label: _labels[fields[index].key] ?? _humanize(fields[index].key),
            value: _displayValue(fields[index].value),
          ),
        ],
      ],
    ),
  );
}

class _ChildTableSection extends StatelessWidget {
  const _ChildTableSection({required this.name, required this.rows});

  final String name;
  final List rows;

  @override
  Widget build(BuildContext context) => AppCard(
    title: _humanize(name),
    subtitle: '${rows.length} ${rows.length == 1 ? 'row' : 'rows'}',
    child: rows.isEmpty
        ? Text('No rows', style: Theme.of(context).textTheme.bodySmall)
        : Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0) ...[
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.medium),
                ],
                _ChildTableRow(row: rows[index], index: index),
              ],
            ],
          ),
  );
}

class _ChildTableRow extends StatelessWidget {
  const _ChildTableRow({required this.row, required this.index});

  final dynamic row;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (row is! Map) {
      return _DetailRow(label: 'Row ${index + 1}', value: _displayValue(row));
    }
    final entries = row.entries.toList();
    final titleEntry = entries.firstWhere(
      (entry) => const {
        'bag_number',
        'payment_type',
        'item_name',
        'item_code',
      }.contains(entry.key),
      orElse: () => MapEntry('row', 'Row ${index + 1}'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _displayValue(titleEntry.value),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.medium),
        for (final entry in entries) ...[
          if (entry.key != titleEntry.key) ...[
            _DetailRow(
              label: _labels[entry.key] ?? _humanize(entry.key),
              value: _displayValue(entry.value),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
        ],
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.record});

  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supplier =
        _text(record['supplier_name1']) ??
        _text(record['supplier_name']) ??
        'Supplier purchase';
    final netPayable = record['net_payable'];
    final name = _text(record['name']) ?? '';
    final docStatus = int.tryParse(record['docstatus']?.toString() ?? '') ?? 0;
    final statusLabel = switch (docStatus) {
      1 => 'Submitted',
      2 => 'Cancelled',
      _ => 'Draft',
    };
    final statusColor = switch (docStatus) {
      1 => theme.extension<AppSemanticColors>()!.success,
      2 => theme.extension<AppSemanticColors>()!.error,
      _ => theme.extension<AppSemanticColors>()!.warning,
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                ),
                child: AppSvgIcon(
                  icon: AppIconName.purchase,
                  size: 24,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(name, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              AppStatusBadge(label: statusLabel, color: statusColor),
            ],
          ),
          if (netPayable != null) ...[
            const SizedBox(height: AppSpacing.standard),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            const SizedBox(height: AppSpacing.standard),
            Row(
              children: [
                Expanded(
                  child: Text('Net payable', style: theme.textTheme.bodyMedium),
                ),
                Text(
                  _formatValue('net_payable', netPayable),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.record,
    required this.title,
    required this.fields,
  });

  final Map<String, dynamic> record;
  final String title;
  final List<String> fields;

  @override
  Widget build(BuildContext context) {
    final visibleFields = [
      for (final key in fields)
        if (_text(record[key]) != null) key,
    ];
    if (visibleFields.isEmpty) return const SizedBox.shrink();

    return AppCard(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < visibleFields.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.medium),
            _DetailRow(
              label:
                  _labels[visibleFields[index]] ??
                  _humanize(visibleFields[index]),
              value: _formatValue(
                visibleFields[index],
                record[visibleFields[index]],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      if (constraints.maxWidth < AppDimensions.detailRowStackBreakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xSmall),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    },
  );
}

const _detailSections = <(String, List<String>)>[
  (
    'Purchase information',
    ['pop_datetime', 'date', 'custom_product_type', 'delivery_type'],
  ),
  (
    'Supplier and collection',
    [
      'supplier_name',
      'supplier_type',
      'collection_location',
      'village',
      'province',
      'island',
      'custom_island',
      'phonemobile_no',
      'custom_contact_number',
      'mobile_no',
    ],
  ),
  (
    'Quantity and pricing',
    [
      'no_of_bag',
      'gross_weight',
      'net_qty',
      'rate',
      'tare',
      'tare15kgsbag',
      'ffa',
      'moisture',
      'total_amount',
    ],
  ),
  (
    'Payment and deductions',
    [
      'mode_of_payment',
      'payment_amount',
      'grand_total',
      'total_deduction',
      'paid',
      'instant_paid',
      'freight',
      'sea_fare',
      'ship_payment',
      'others',
      'custom_paid_advance',
      'advances',
      'gst',
    ],
  ),
  (
    'Accounting and references',
    [
      'company',
      'purchase_invoice',
      'ref_pv_no',
      'journal_entry',
      'payment_entry',
      'default_accepted_warehouse',
      'vesel',
      'vesel_name',
      'paid_to',
      'othershipping_account',
      'bank_account',
      'cash_account',
      'inventory_account',
      'advance_receivable_account',
    ],
  ),
  (
    'Record metadata',
    [
      'owner',
      'creation',
      'modified',
      'modified_by',
      'idx',
      'naming_series',
      'doctype',
    ],
  ),
];

const _labels = <String, String>{
  'name': 'Purchase number',
  'pop_datetime': 'Purchase date',
  'docstatus': 'Status',
  'custom_product_type': 'Product type',
  'supplier_name1': 'Supplier',
  'supplier_name': 'Supplier ID',
  'supplier_type': 'Supplier type',
  'collection_location': 'Collection location',
  'phonemobile_no': 'Phone number',
  'gross_weight': 'Gross weight (kg)',
  'net_qty': 'Net quantity (kg)',
  'no_of_bag': 'Number of bags',
  'mode_of_payment': 'Payment method',
  'payment_amount': 'Payment amount',
  'grand_total': 'Grand total',
  'total_deduction': 'Total deductions',
  'net_payable': 'Net payable',
  'purchase_invoice': 'Purchase invoice',
  'payment_entry': 'Payment entry',
  'date': 'Transaction date',
  'delivery_type': 'Delivery type',
  'custom_island': 'Island',
  'mobile_no': 'Mobile number',
  'custom_contact_number': 'Contact number',
  'tare15kgsbag': '15 kg bag tare',
  'total_amount': 'Total amount',
  'instant_paid': 'Instant payment',
  'freight': 'Freight',
  'sea_fare': 'Sea fare',
  'ship_payment': 'Shipping payment',
  'custom_paid_advance': 'Paid advance',
  'ref_pv_no': 'Reference PV number',
  'journal_entry': 'Journal entry',
  'default_accepted_warehouse': 'Accepted warehouse',
  'vesel': 'Vessel ID',
  'vesel_name': 'Vessel',
  'othershipping_account': 'Other shipping account',
  'advance_receivable_account': 'Advance receivable account',
  'idx': 'Record index',
};

String? _text(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _hasDetailValue(dynamic value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is Map || value is List) return value.isNotEmpty;
  return true;
}

String _formatValue(String key, dynamic value) {
  if (key == 'docstatus') {
    return value.toString() == '1' ? 'Submitted' : 'Draft';
  }
  if (key == 'paid') return value.toString() == '1' ? 'Paid' : 'Unpaid';
  final number = value is num ? value : num.tryParse(value.toString());
  if (number != null &&
      (key.contains('amount') ||
          key.contains('total') ||
          key.contains('payable') ||
          key == 'rate' ||
          key == 'gross_weight' ||
          key == 'net_qty')) {
    return number.toStringAsFixed(2);
  }
  return value.toString();
}

String _displayValue(dynamic value) {
  if (value == null) return '—';
  if (value is Map) {
    return value.entries
        .map((entry) => '${_humanize(entry.key.toString())}: ${entry.value}')
        .join(', ');
  }
  if (value is List) {
    return value.isEmpty ? '—' : value.map(_displayValue).join(', ');
  }
  return value.toString().trim().isEmpty ? '—' : value.toString();
}

String _humanize(String key) => key
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
