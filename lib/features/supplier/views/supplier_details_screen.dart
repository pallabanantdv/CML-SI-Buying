import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_expandable_section.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_info_row.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../viewmodels/supplier_viewmodel.dart';

class SupplierDetailsScreen extends StatefulWidget {
  const SupplierDetailsScreen({super.key, required this.supplierId});
  final String supplierId;

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant SupplierDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.supplierId != widget.supplierId) _scheduleLoad();
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          context.read<SupplierViewModel>().loadSupplier(widget.supplierId),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<SupplierViewModel>(
    builder: (context, vm, _) {
      final matches = vm.selectedSupplierId == widget.supplierId;
      final record = matches ? vm.selectedSupplier : null;
      final loading =
          !matches ||
          (record == null &&
              (vm.isLoadingDetail || vm.detailErrorMessage == null));
      return Scaffold(
        appBar: const AppAppBar(
          title: AppHeaderTitle(title: 'Supplier details'),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.detailContentMaxWidth,
              ),
              child: SkeletonReveal(
                loading: loading,
                child: loading
                    ? const _SupplierDetailsSkeleton()
                    : record == null
                    ? AppErrorWidget(
                        message:
                            vm.detailErrorMessage ??
                            'No supplier details were returned.',
                        onRetry: () =>
                            unawaited(vm.loadSupplier(widget.supplierId)),
                      )
                    : RefreshIndicator(
                        onRefresh: () => vm.loadSupplier(widget.supplierId),
                        child: _details(record, vm.detailErrorMessage),
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _details(Map<String, dynamic> record, String? error) {
    const groups = <String, List<String>>{
      'Supplier information': [
        'name',
        'supplier_name',
        'supplier_group',
        'supplier_type',
        'custom_status',
        'disabled',
        'is_frozen',
        'on_hold',
      ],
      'Contact and address': [
        'custom_contact_number',
        'mobile_no',
        'phone',
        'email_id',
        'website',
        'supplier_primary_contact',
        'primary_contact',
        'supplier_primary_address',
        'primary_address',
        'village',
        'custom_island',
        'province',
        'country',
      ],
      'Tax and payment information': [
        'tax_id',
        'tax_category',
        'tax_withholding_category',
        'default_currency',
        'default_bank_account',
        'payment_terms',
        'is_internal_supplier',
        'represents_company',
      ],
    };
    final groupedKeys = groups.values.expand((keys) => keys).toSet();
    final remaining = record.entries
        .where((e) => !groupedKeys.contains(e.key) && _visible(e.key))
        .toList();
    return ListView(
      key: PageStorageKey('supplier-details-${widget.supplierId}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.pageGutter),
      children: [
        AppCard(
          title: record['supplier_name']?.toString() ?? widget.supplierId,
          subtitle: widget.supplierId,
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.cardGap),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        for (final group in groups.entries)
          if (group.value.any(record.containsKey)) ...[
            const SizedBox(height: AppSpacing.cardGap),
            AppCard(
              title: group.key,
              child: _fields({
                for (final key in group.value)
                  if (record.containsKey(key)) key: record[key],
              }),
            ),
          ],
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(
            title: 'Additional details',
            child: _fields(Map.fromEntries(remaining)),
          ),
        ],
      ],
    );
  }

  static bool _visible(String key) =>
      !key.startsWith('_') &&
      !RegExp(
        r'password|secret|token|cookie|authorization|api_key|reset_key',
        caseSensitive: false,
      ).hasMatch(key);

  Widget _fields(Map<String, dynamic> fields) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in fields.entries.where((e) => _visible(e.key)))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _value(entry.key, entry.value),
        ),
    ],
  );

  Widget _value(String key, dynamic value) {
    if (value is Map) {
      return AppExpandableSection(
        title: _label(key),
        child: _fields(Map<String, dynamic>.from(value)),
      );
    }
    if (value is List && value.isNotEmpty && value.every((row) => row is Map)) {
      return AppExpandableSection(
        title: '${_label(key)} (${value.length})',
        child: Column(
          children: [
            for (var i = 0; i < value.length; i++) ...[
              if (i > 0) const Divider(),
              _fields(Map<String, dynamic>.from(value[i] as Map)),
            ],
          ],
        ),
      );
    }
    const flags = {
      'disabled',
      'is_frozen',
      'on_hold',
      'is_internal_supplier',
      'is_transporter',
      'allow_purchase',
      'allow_sales',
    };
    final text =
        value == null ||
            value.toString().trim().isEmpty ||
            (value is List && value.isEmpty)
        ? '\u2014'
        : flags.contains(key)
        ? (value == true || value.toString() == '1' ? 'Yes' : 'No')
        : value is List
        ? value.join(', ')
        : value.toString();
    return AppInfoRow(label: _label(key), value: text, selectable: true);
  }

  static String _label(String key) {
    if (key == 'name') return 'Supplier ID';
    return key
        .replaceFirst(RegExp(r'^custom_'), '')
        .split('_')
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length <= 2
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _SupplierDetailsSkeleton extends StatelessWidget {
  const _SupplierDetailsSkeleton();
  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    label: 'Loading supplier details...',
    child: ListView(
      padding: const EdgeInsets.all(AppDimensions.pageGutter),
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SkeletonCard(child: SkeletonInfoRows(count: 5)),
          const SizedBox(height: AppSpacing.cardGap),
        ],
      ],
    ),
  );
}
