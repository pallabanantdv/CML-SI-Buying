import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_paginated_list.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_card_heading.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../viewmodels/payment_entry_list_viewmodel.dart';

class PaymentEntryListScreen extends StatefulWidget {
  const PaymentEntryListScreen({super.key});
  @override
  State<PaymentEntryListScreen> createState() => _PaymentEntryListScreenState();
}

class _PaymentEntryListScreenState extends State<PaymentEntryListScreen> {
  bool _creating = false;
  final _searchController = TextEditingController();
  final List<DropdownMenuItem<String>> _supplierItems = [];
  Timer? _searchDebounce;
  int _supplierRequest = 0;
  bool _loadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<PaymentEntryListViewModel>();
      unawaited(vm.load());
      unawaited(_loadInitialSuppliers(vm));
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchEntries(PaymentEntryListViewModel vm, String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) unawaited(vm.search(value));
    });
  }

  Future<void> _loadInitialSuppliers(PaymentEntryListViewModel vm) async {
    try {
      await _searchSuppliers(vm, '');
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        'Unable to load suppliers. Search in the supplier filter to retry.',
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _loadingSuppliers = false);
    }
  }

  Future<List<DropdownMenuItem<String>>> _searchSuppliers(
    PaymentEntryListViewModel vm,
    String query,
  ) async {
    final request = ++_supplierRequest;
    final rows = await vm.searchSuppliers(query);
    final results = [
      for (final row in rows)
        DropdownMenuItem<String>(
          value: '${row['name']}',
          child: Text(
            '${row['supplier_name'] ?? row['name']} (${row['name']})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];
    if (!mounted || request != _supplierRequest) return results;

    DropdownMenuItem<String>? selectedItem;
    for (final item in _supplierItems) {
      if (item.value == vm.supplier) {
        selectedItem = item;
        break;
      }
    }
    setState(() {
      _supplierItems
        ..clear()
        ..addAll(results)
        ..addAll(
          selectedItem != null &&
                  !results.any((item) => item.value == selectedItem!.value)
              ? [selectedItem]
              : const <DropdownMenuItem<String>>[],
        );
    });
    return results;
  }

  Future<void> _create(PaymentEntryListViewModel vm) async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final name = await context.pushNamedOnce<String>(
        RouteNames.createPaymentEntry,
      );
      if (!mounted || name == null) return;
      if (vm.status == null) {
        await vm.load();
      } else {
        await vm.filter(null);
      }
      if (mounted) {
        AppSnackbar.show(
          context,
          'Payment entry $name saved as draft',
          type: AppMessageType.success,
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _submit(PaymentEntryListViewModel vm, String name) async {
    if (vm.submittingName != null || vm.loading || vm.loadingMore) return;
    final success = await vm.submit(name);
    if (!mounted) return;
    AppSnackbar.show(
      context,
      success
          ? 'Payment entry $name submitted'
          : vm.error ?? 'Unable to submit payment entry.',
      type: success ? AppMessageType.success : AppMessageType.error,
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<PaymentEntryListViewModel>(
    builder: (context, vm, _) {
      final busy = vm.submittingName != null;
      return Scaffold(
        appBar: AppAppBar(
          title: const AppHeaderTitle(title: 'Payment entries'),
          actions: [
            TextButton.icon(
              onPressed: busy || _creating ? null : () => _create(vm),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New entry'),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.detailContentMaxWidth,
              ),
              child: AppPaginatedList(
                hasMore: vm.hasMore,
                loading: vm.loading || vm.loadingMore || busy,
                error: vm.error,
                onLoadMore: () => vm.load(more: true),
                child: RefreshIndicator(
                  onRefresh: () => vm.load(),
                  child: ListView.builder(
                    itemCount: vm.records.length + 1,
                    itemBuilder: (context, index) {
                      if (index > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _entry(vm, vm.records[index - 1]),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppTextField(
                                  controller: _searchController,
                                  label: 'Search payment entries',
                                  hint: 'Entry ID, supplier name or ID',
                                  prefixIcon: const Icon(Icons.search),
                                  textInputAction: TextInputAction.search,
                                  onChanged: (value) =>
                                      _searchEntries(vm, value),
                                  suffixIcon:
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: _searchController,
                                        builder: (context, value, _) =>
                                            value.text.isEmpty
                                            ? const SizedBox.shrink()
                                            : IconButton(
                                                tooltip: 'Clear search',
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                                onPressed: () {
                                                  _searchDebounce?.cancel();
                                                  _searchController.clear();
                                                  unawaited(vm.search(''));
                                                },
                                              ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 2,
                                child: AppDropdown<String>(
                                  label: 'Supplier',
                                  value: vm.supplier,
                                  items: _supplierItems,
                                  enabled: !busy && !_loadingSuppliers,
                                  hint: 'All',
                                  onSearch: (query) =>
                                      _searchSuppliers(vm, query),
                                  onChanged: (value) =>
                                      unawaited(vm.filterSupplier(value)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final choice in const <(String, int?)>[
                                  ('All', null),
                                  ('Draft', 0),
                                  ('Submitted', 1),
                                  ('Cancelled', 2),
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(choice.$1),
                                      selected: vm.status == choice.$2,
                                      onSelected: busy
                                          ? null
                                          : (_) =>
                                                unawaited(vm.filter(choice.$2)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (vm.loading && vm.records.isEmpty)
                            const SkeletonShimmer(
                              label: 'Loading payment entries...',
                              child: SkeletonInfoRows(count: 8),
                            )
                          else if (vm.error != null && vm.records.isEmpty)
                            AppErrorWidget(
                              message: vm.error!,
                              onRetry: () => unawaited(vm.load()),
                            )
                          else ...[
                            if (vm.error != null) ...[
                              Text(
                                vm.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => unawaited(vm.load()),
                                child: const Text('Refresh'),
                              ),
                            ],
                            if (vm.loading) const LinearProgressIndicator(),
                            if (vm.records.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No payment entries found.'),
                              ),
                          ],
                        ],
                      );
                    },
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _entry(PaymentEntryListViewModel vm, Map<String, dynamic> record) {
    final name = '${record['name']}';
    final status = int.tryParse('${record['docstatus']}');
    final label = switch (status) {
      0 => 'Draft',
      1 => 'Submitted',
      2 => 'Cancelled',
      _ => 'Unknown',
    };
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => context.pushNamedOnce<void>(
        RouteNames.paymentEntryDetails,
        pathParameters: {'documentName': name},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCardHeading(
            title: name,
            trailing: AppStatusBadge(
              label: label,
              color: status == 1
                  ? colors.primary
                  : status == 2
                  ? colors.error
                  : colors.secondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${record['party_name'] ?? record['party'] ?? ''}',
            style: textTheme.bodySmall,
          ),
          Text(
            '${record['posting_date'] ?? ''} \u00b7 ${record['company'] ?? ''}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${record['paid_from_account_currency'] ?? ''} ${AppNumberFormat.amount(num.tryParse('${record['paid_amount']}') ?? 0)}',
            style: textTheme.titleSmall,
          ),
          if (record['mode_of_payment'] != null)
            Text('${record['mode_of_payment']}', style: textTheme.bodySmall),
          if (status == 0) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Submit',
              isLoading: vm.submittingName == name,
              onPressed:
                  vm.loading || vm.loadingMore || vm.submittingName != null
                  ? null
                  : () => _submit(vm, name),
            ),
          ],
        ],
      ),
    );
  }
}
