import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_expandable_section.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_info_row.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../viewmodels/supplier_viewmodel.dart';

class PaymentEntryDetailsScreen extends StatefulWidget {
  const PaymentEntryDetailsScreen({super.key, required this.documentName});

  final String documentName;

  @override
  State<PaymentEntryDetailsScreen> createState() =>
      _PaymentEntryDetailsScreenState();
}

class _PaymentEntryDetailsScreenState extends State<PaymentEntryDetailsScreen> {
  Map<String, dynamic>? _record;
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant PaymentEntryDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentName != widget.documentName) {
      _record = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = await context
          .read<SupplierViewModel>()
          .repository
          .payments
          .details(widget.documentName);
      if (!mounted || request != _request) return;
      setState(() => _record = record);
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error is AppException
            ? error.message
            : 'Unable to load payment entry details. Please retry.';
      });
    } finally {
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    }
  }

  static const _groups = {
    'Payment information': [
      'posting_date',
      'company',
      'payment_type',
      'party',
      'party_name',
      'mode_of_payment',
    ],
    'Accounts and amounts': [
      'paid_from',
      'paid_from_account_currency',
      'paid_to',
      'paid_to_account_currency',
      'paid_amount',
      'received_amount',
      'total_allocated_amount',
      'unallocated_amount',
      'difference_amount',
    ],
    'Transaction details': [
      'reference_no',
      'reference_date',
      'bank',
      'bank_account',
      'party_bank_account',
      'remarks',
    ],
  };
  static const _metadata = {
    'doctype',
    'docstatus',
    'idx',
    'parent',
    'parentfield',
    'parenttype',
  };

  bool _hasValue(dynamic value) =>
      value != null &&
      (value is! String || value.trim().isNotEmpty) &&
      (value is! Iterable || value.isNotEmpty) &&
      (value is! Map || value.isNotEmpty);

  String _label(String key) => key
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  String _value(String key, dynamic value) {
    if (value is num && (key.contains('amount') || key.contains('balance'))) {
      return AppNumberFormat.amount(value);
    }
    return '$value';
  }

  Widget _fields(Map<String, dynamic> fields) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in fields.entries)
        if (!entry.key.startsWith('_') &&
            !_metadata.contains(entry.key) &&
            _hasValue(entry.value))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: entry.value is List
                ? _table(entry.key, entry.value as List)
                : entry.value is Map
                ? AppExpandableSection(
                    initiallyExpanded: true,
                    title: _label(entry.key),
                    child: _fields(
                      Map<String, dynamic>.from(entry.value as Map),
                    ),
                  )
                : AppInfoRow(
                    label: _label(entry.key),
                    value: _value(entry.key, entry.value),
                    selectable: true,
                  ),
          ),
    ],
  );

  Widget _table(String key, List rows) => AppExpandableSection(
    title: '${_label(key)} (${rows.length})',
    initiallyExpanded: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: AppExpandableSection(
              initiallyExpanded: true,
              title: '${_label(key)} ${i + 1}',
              child: rows[i] is Map
                  ? _fields(Map<String, dynamic>.from(rows[i] as Map))
                  : Text('${rows[i]}'),
            ),
          ),
      ],
    ),
  );

  Widget _referenceAllocations(Map<String, dynamic> record) {
    final rows = record['references'];
    if (rows is! List || rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sectionGap),
      child: _table('references', [
        for (final row in rows.whereType<Map>())
          {
            for (final key in const [
              'reference_doctype',
              'reference_name',
              'due_date',
              'total_amount',
              'outstanding_amount',
              'allocated_amount',
            ])
              key: row[key],
          },
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final status = int.tryParse('${record?['docstatus']}');
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const AppAppBar(
        title: AppHeaderTitle(title: 'Payment entry details'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.detailContentMaxWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.pageGutter),
                children: [
                  if (_loading && record == null)
                    const SkeletonShimmer(
                      label: 'Loading payment entry details...',
                      child: SkeletonInfoRows(count: 8),
                    ),
                  if (_error != null)
                    AppErrorWidget(
                      message: _error!,
                      onRetry: () => unawaited(_load()),
                    ),
                  if (record != null) ...[
                    if (_loading) const LinearProgressIndicator(),
                    AppCard(
                      title: widget.documentName,
                      trailing: AppStatusBadge(
                        label: switch (status) {
                          0 => 'Draft',
                          1 => 'Submitted',
                          2 => 'Cancelled',
                          _ => 'Unknown',
                        },
                        color: status == 1
                            ? colors.primary
                            : status == 2
                            ? colors.error
                            : colors.secondary,
                      ),
                    ),
                    for (final group in _groups.entries)
                      if (group.value.any((key) => _hasValue(record[key]))) ...[
                        const SizedBox(height: AppSpacing.sectionGap),
                        AppExpandableSection(
                          initiallyExpanded: true,
                          title: group.key,
                          child: _fields({
                            for (final key in group.value) key: record[key],
                          }),
                        ),
                      ],
                    _referenceAllocations(record),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
