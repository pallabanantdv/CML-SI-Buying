import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/diagnostics/app_diagnostics.dart';
import '../../../core/errors/app_exception.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_card_heading.dart';
import '../../../shared/widgets/app_info_row.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../config/routes/route_names.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../widgets/purchase_detail_skeleton.dart';
import '../../../shared/widgets/app_expandable_section.dart';
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
  bool _loadingInvoice = false;
  bool _loadingPop = false;

  Future<void> _viewInvoice(PointOfPurchaseViewModel vm) async {
    if (_loadingInvoice) return;
    final name = widget.documentName;
    setState(() => _loadingInvoice = true);
    try {
      final document = await vm.loadInvoicePreview(name);
      if (!mounted || name != widget.documentName) return;
      await context.pushNamedOnce(
        RouteNames.invoiceHtmlPrintPreview,
        extra: document,
      );
    } catch (error) {
      if (!mounted || name != widget.documentName) return;
      AppSnackbar.show(
        context,
        error is AppException
            ? error.message
            : 'Unable to load the invoice. Please retry.',
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _loadingInvoice = false);
    }
  }

  Future<void> _printPurchase(PointOfPurchaseViewModel vm) async {
    if (_loadingPop) return;
    final name = widget.documentName;
    setState(() => _loadingPop = true);
    try {
      final document = await vm.loadPopPreview(name);
      if (!mounted || name != widget.documentName) return;
      await context.pushNamedOnce(RouteNames.popPrintPreview, extra: document);
    } catch (error) {
      if (!mounted || name != widget.documentName) return;
      AppSnackbar.show(
        context,
        error is AppException
            ? error.message
            : 'Unable to open the POP template. Please retry.',
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _loadingPop = false);
    }
  }

  PreferredSizeWidget _invoiceAction(PointOfPurchaseViewModel vm) =>
      PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View invoice',
                  variant: AppButtonVariant.outlined,
                  isLoading: _loadingInvoice,
                  onPressed:
                      _loadingInvoice ||
                          _loadingPop ||
                          vm.isLoadingDetail ||
                          vm.isRefreshingDetail
                      ? null
                      : () => _viewInvoice(vm),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Print',
                  isLoading: _loadingPop,
                  onPressed:
                      _loadingInvoice ||
                          _loadingPop ||
                          vm.isLoadingDetail ||
                          vm.isRefreshingDetail
                      ? null
                      : () => _printPurchase(vm),
                ),
              ),
            ],
          ),
        ),
      );
  @override
  void initState() {
    super.initState();
    AppDiagnostics.write('[$runtimeType] initState');
    _scheduleLoad();
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<PointOfPurchaseViewModel>().loadPointOfPurchase(
          widget.documentName,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(covariant PointOfPurchaseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentName != widget.documentName) _scheduleLoad();
  }

  @override
  Widget build(BuildContext context) => Consumer<PointOfPurchaseViewModel>(
    builder: (context, viewModel, _) => Scaffold(
      appBar: AppAppBar(
        title: const AppHeaderTitle(title: 'Purchase details'),
        bottom:
            viewModel.selectedName == widget.documentName &&
                int.tryParse('${viewModel.selectedRecord?['docstatus']}') == 0
            ? _headerActions(viewModel)
            : viewModel.selectedName == widget.documentName &&
                  int.tryParse('${viewModel.selectedRecord?['docstatus']}') == 1
            ? _invoiceAction(viewModel)
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.detailContentMaxWidth,
            ),
            child: SkeletonReveal(
              loading:
                  (viewModel.isLoadingDetail &&
                      viewModel.selectedRecord == null) ||
                  viewModel.selectedName != widget.documentName,
              child: RefreshIndicator(
                onRefresh: () =>
                    viewModel.loadPointOfPurchase(widget.documentName),
                child: _buildContent(context, viewModel),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  PreferredSizeWidget _headerActions(PointOfPurchaseViewModel vm) {
    final width = (MediaQuery.sizeOf(context).width - 32).clamp(1.0, 360.0);
    final painter = TextPainter(
      text: TextSpan(
        text: 'Update',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: ((width - 8) / 2 - 32).clamp(1.0, double.infinity));
    final height = (painter.height + 16).clamp(48.0, double.infinity);
    painter.dispose();
    final busy = vm.isSubmitting || vm.isCreating || vm.isLoadingDetail;
    return PreferredSize(
      preferredSize: Size.fromHeight(height + 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: width,
            height: height,
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Update',
                    variant: AppButtonVariant.outlined,
                    onPressed: busy ? null : () => _update(vm),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Submit',
                    isLoading: vm.isSubmitting,
                    onPressed: busy || vm.isRefreshingDetail
                        ? null
                        : () => _submit(vm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _update(PointOfPurchaseViewModel viewModel) async {
    if (viewModel.isSubmitting ||
        viewModel.isCreating ||
        viewModel.selectedName != widget.documentName ||
        viewModel.selectedRecord == null) {
      return;
    }
    final updated = await context.pushNamedOnce<bool>(
      RouteNames.createPointOfPurchase,
      queryParameters: {'documentName': widget.documentName},
      extra: Map<String, dynamic>.from(viewModel.selectedRecord!),
    );
    if (!mounted || updated != true) return;
    await viewModel.loadPointOfPurchase(widget.documentName);
    if (mounted) {
      AppSnackbar.show(
        context,
        'Purchase updated successfully',
        type: AppMessageType.success,
      );
    }
  }

  Future<void> _submit(PointOfPurchaseViewModel viewModel) async {
    if (viewModel.isSubmitting) return;
    final name = widget.documentName;
    final success = await viewModel.submitPointOfPurchase(name);
    if (!mounted || widget.documentName != name) return;
    AppSnackbar.show(
      context,
      success
          ? 'Purchase submitted successfully'
          : viewModel.submitErrorMessage ?? 'Unable to submit this purchase.',
      type: success ? AppMessageType.success : AppMessageType.error,
    );
  }

  Widget _buildContent(
    BuildContext context,
    PointOfPurchaseViewModel viewModel,
  ) {
    if (AppDiagnostics.enabled) {
      AppDiagnostics.write(
        '[$runtimeType] render loading=${viewModel.isLoadingDetail} error=${viewModel.detailErrorMessage != null}',
      );
    }
    if ((viewModel.isLoadingDetail && viewModel.selectedRecord == null) ||
        viewModel.selectedName != widget.documentName) {
      return const PurchaseDetailSkeleton();
    }
    if (viewModel.detailErrorMessage != null &&
        viewModel.selectedRecord == null) {
      return AppErrorWidget(
        message: viewModel.detailErrorMessage!,
        onRetry: () =>
            unawaited(viewModel.loadPointOfPurchase(widget.documentName)),
      );
    }
    final record = viewModel.selectedDetail?.toJson();
    if (record == null) {
      return AppErrorWidget(
        message: 'No purchase details were returned.',
        onRetry: () =>
            unawaited(viewModel.loadPointOfPurchase(widget.documentName)),
      );
    }

    final childTables = record.entries
        .where(
          (entry) => _childFields.containsKey(entry.key) && entry.value is List,
        )
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.pageGutter),
      children: [
        AppExpandableSection(
          title: 'Purchase overview',
          initiallyExpanded: true,
          child: _OverviewCard(record: record),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        for (final section in _detailSections)
          if (section.$2.any((field) => _text(record[field]) != null)) ...[
            _DetailSection(
              record: record,
              title: section.$1,
              fields: section.$2,
              collapsible: true,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
        for (final table in childTables) ...[
          AppExpandableSection(
            title:
                '${_tableTitle(table.key)} (${(table.value as List).length})',
            initiallyExpanded: table.key == 'supplier_pop_item',
            child: _ChildTableSection(
              name: table.key,
              rows: table.value as List,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ],
    );
  }
}

String _tableTitle(String name) => switch (name) {
  'supplier_pop_item' => 'Purchase items',
  'total_bag' => 'Bags and weight',
  'advance' || 'supplier_advance_allocation' => 'Advance allocations',
  'pop_cash_payment' => 'Cash payments',
  _ => _humanize(name),
};

class _ChildTableSection extends StatelessWidget {
  const _ChildTableSection({required this.name, required this.rows});
  final String name;
  final List rows;
  @override
  Widget build(BuildContext context) => rows.isEmpty
      ? Text('No rows', style: Theme.of(context).textTheme.bodySmall)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) ...[
                const SizedBox(height: AppSpacing.cardGap),
                const Divider(),
                const SizedBox(height: AppSpacing.cardGap),
              ],
              _ChildTableRow(
                row: rows[index] is Map
                    ? {
                        for (final entry in (rows[index] as Map).entries)
                          if (_childFields[name]!.contains(entry.key))
                            entry.key: entry.value,
                      }
                    : const <String, dynamic>{},
                index: index,
              ),
            ],
          ],
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
        const SizedBox(height: AppSpacing.small),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardHeading(
            title: name,
            trailing: AppStatusBadge(label: statusLabel, color: statusColor),
          ),
          const SizedBox(height: 4),
          Text(supplier, style: theme.textTheme.bodyMedium),
          if (netPayable != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Net payable', style: theme.textTheme.bodySmall),
                Text(
                  _formatValue('net_payable', netPayable),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
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
    this.collapsible = false,
  });

  final bool collapsible;
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

    final content = AppInfoGrid(
      fields: [
        for (final field in visibleFields)
          (
            _labels[field] ?? _humanize(field),
            _formatValue(field, record[field]),
          ),
      ],
    );
    if (collapsible) return AppExpandableSection(title: title, child: content);
    return AppCard(title: title, child: content);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppInfoRow(label: label, value: value);
}

const _detailSections = <(String, List<String>)>[
  (
    'Supplier and collection',
    [
      'collection_location',
      'custom_product_type',
      'supplier_name',
      'supplier_name1',
      'village',
      'province',
      'supplier_type',
      'island',
      'phonemobile_no',
    ],
  ),
  (
    'Purchase and delivery',
    [
      'date',
      'time',
      'pop_datetime',
      'company',
      'delivery_type',
      'courier_name',
      'ffa',
      'moisture',
      'copra_bag_level',
      'contract_no',
      'ref_pv_no',
    ],
  ),
  ('Bags and weight', ['no_of_bag', 'gross_weight', 'tare15kgsbag']),
  (
    'Pricing and deductions',
    [
      'rate',
      'freight',
      'others',
      'sea_fare',
      'custom_paid_advance',
      'advances',
      'ship_payment',
      'total_amount',
      'grand_total',
      'total_deduction',
      'net_payable',
    ],
  ),
  (
    'Payment and accounts',
    [
      'default_accepted_warehouse',
      'vesel',
      'vesel_name',
      'bank_account',
      'cash_account',
      'supplier_payable_account',
      'othershipping_account',
      'inventory_account',
      'advance_receivable_account',
      'instant_paid',
    ],
  ),
  // (
  //   'Saved purchase values',
  //   [
  //     'naming_series',
  //     'net_qty',
  //     'cashbank_account',
  //     'paid_to',
  //     'journal_entry',
  //   ],
  // ),
];

const _childFields = <String, Set<String>>{
  'total_bag': {'bag_number', 'weight', 'tarebagkg'},
  'supplier_pop_item': {
    'item_code',
    'item_name',
    'qty',
    'uom',
    'rate',
    'total_amount',
  },
  'advance': {
    'reference_name',
    'reference_type',
    'remarks',
    'advance_amount',
    'allocated_amount',
  },
  'pop_cash_payment': {
    'payment_type',
    'paid_amount',
    'reference_no',
    'reference_date',
    'payment_from',
    'check_knlg',
  },
};

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
  'tare15kgsbag': 'Tare per bag (kg)',
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
    return AppNumberFormat.amount(number);
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
