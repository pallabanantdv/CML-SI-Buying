import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_expandable_section.dart';
import '../../../shared/widgets/app_info_row.dart';
import '../../../core/models/html_print_document.dart';
import '../../../core/widgets/html_print_preview_screen.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../viewmodels/supplier_viewmodel.dart';
import 'create_supplier_screen.dart';

class SupplierDetailsScreen extends StatefulWidget {
  const SupplierDetailsScreen({super.key, required this.supplierId});
  final String supplierId;

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  HtmlPrintDocument? _preview;
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant SupplierDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.supplierId != widget.supplierId) {
      ++_request;
      _preview = null;
      _loading = true;
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          context.read<SupplierViewModel>().loadSupplier(widget.supplierId),
        );
        unawaited(_loadPreview());
      }
    });
  }

  Future<void> _loadPreview() async {
    final request = ++_request;
    final vm = context.read<SupplierViewModel>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final document = await vm.loadPrintPreview(widget.supplierId);
    if (!mounted || request != _request) return;
    setState(() {
      _preview = document;
      _loading = false;
      _error = document == null
          ? vm.printError ?? 'Unable to load the supplier card. Please retry.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppAppBar(
      title: const AppHeaderTitle(title: 'Supplier details'),
      actions: [
        Consumer<SupplierViewModel>(
          builder: (context, vm, _) => TextButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
            onPressed:
                vm.isLoadingDetail ||
                    vm.selectedSupplierId != widget.supplierId ||
                    vm.selectedSupplier == null
                ? null
                : () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: vm,
                          child: CreateSupplierScreen(
                            supplier: Map<String, dynamic>.from(
                              vm.selectedSupplier!,
                            ),
                          ),
                        ),
                      ),
                    );
                    if (saved == true && mounted) {
                      await vm.loadSupplier(widget.supplierId);
                      if (mounted) await _loadPreview();
                    }
                  },
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Consumer<SupplierViewModel>(
        builder: (context, vm, _) {
          final record = vm.selectedSupplierId == widget.supplierId
              ? vm.selectedSupplier
              : null;
          final groupedKeys = _groups.values.expand((keys) => keys).toSet();
          final remaining =
              record?.entries
                  .where(
                    (entry) =>
                        !groupedKeys.contains(entry.key) && _visible(entry.key),
                  )
                  .toList() ??
              [];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.detailContentMaxWidth,
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    vm.loadSupplier(widget.supplierId),
                    _loadPreview(),
                  ]);
                },
                child: ListView(
                  key: PageStorageKey('supplier-details-${widget.supplierId}'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  // padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      // color: Colors.red,
                      height: MediaQuery.sizeOf(context).height * 0.3,
                      child: _loading
                          ? const SkeletonShimmer(
                              label: 'Loading supplier card...',
                              child: SkeletonBox(height: 260),
                            )
                          : _error != null
                          ? AppErrorWidget(
                              message: _error!,
                              onRetry: _loadPreview,
                            )
                          : HtmlPrintPreviewScreen(
                              key: ObjectKey(_preview),
                              embedded: true,
                              cardOnly: true,
                              htmlContent: _preview!.html,
                              title: _preview!.title,
                              baseUrl: _preview!.baseUrl,
                              cookies: _preview!.cookies,
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (record != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            AppCard(
                              title:
                                  record['supplier_name']?.toString() ??
                                  widget.supplierId,
                              subtitle: widget.supplierId,
                            ),
                            for (final group in _groups.entries)
                              if (group.value.any(record.containsKey)) ...[
                                const SizedBox(height: 16),
                                AppExpandableSection(
                                  initiallyExpanded: true,
                                  key: ValueKey(
                                    '${widget.supplierId}-${group.key}',
                                  ),
                                  title: group.key,
                                  child: _fields({
                                    for (final key in group.value)
                                      if (record.containsKey(key))
                                        key: record[key],
                                  }),
                                ),
                              ],
                            // if (remaining.isNotEmpty) ...[
                            //   const SizedBox(height: 16),
                            //   AppCard(
                            //     title: 'Additional details',
                            //     child: _fields(Map.fromEntries(remaining)),
                            //   ),
                            // ],
                          ],
                        ),
                      ),
                    ] else if (vm.isLoadingDetail)
                      const SkeletonShimmer(
                        label: 'Loading supplier details...',
                        child: SkeletonInfoRows(count: 5),
                      ),
                    if (vm.detailErrorMessage != null)
                      AppErrorWidget(
                        message: vm.detailErrorMessage!,
                        onRetry: () => vm.loadSupplier(widget.supplierId),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  static const _groups = <String, List<String>>{
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
