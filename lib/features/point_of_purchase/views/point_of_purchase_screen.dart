import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigation.dart';

import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/diagnostics/app_diagnostics.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../widgets/purchase_list_skeleton.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../viewmodels/point_of_purchase_viewmodel.dart';
import '../widgets/app_purchase_card.dart';

class PointOfPurchaseScreen extends StatefulWidget {
  const PointOfPurchaseScreen({super.key});
  @override
  State<PointOfPurchaseScreen> createState() => _PointOfPurchaseScreenState();
}

class _PointOfPurchaseScreenState extends State<PointOfPurchaseScreen> {
  final _search = TextEditingController();
  int? _status;
  String? _supplier;
  final _supplierLabels = <String, String>{};
  String? _productType;
  @override
  void initState() {
    super.initState();
    AppDiagnostics.write('[POP SCREEN] initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<PointOfPurchaseViewModel>().ensureLoaded());
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<PointOfPurchaseViewModel>(
    builder: (context, vm, _) => Scaffold(
      appBar: AppAppBar(
        title: const AppHeaderTitle(title: 'Purchases'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'New purchase',
              child: AppButton(
                label: 'New',
                icon: AppIconName.add,
                variant: AppButtonVariant.text,
                expand: false,
                onPressed: _createPurchase,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.purchaseListMaxWidth,
            ),
            child: SkeletonReveal(
              loading:
                  !vm.hasLoaded &&
                  vm.records.isEmpty &&
                  (vm.isLoading || (!vm.hasLoaded && vm.errorMessage == null)),
              child: _content(vm),
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> _createPurchase() async {
    final created = await context.pushNamedOnce<bool>(
      RouteNames.createPointOfPurchase,
    );
    if (created == true && mounted) {
      AppSnackbar.show(context, 'Purchase saved', type: AppMessageType.success);
    }
  }

  Widget _content(PointOfPurchaseViewModel vm) {
    if (AppDiagnostics.enabled) {
      AppDiagnostics.write(
        '[POP SCREEN] render loading=${vm.isLoading} count=${vm.records.length}',
      );
    }
    final loading =
        !vm.hasLoaded &&
        vm.records.isEmpty &&
        (vm.isLoading || (!vm.hasLoaded && vm.errorMessage == null));
    if (!loading &&
        vm.errorMessage != null &&
        !vm.hasLoaded &&
        vm.records.isEmpty) {
      return AppErrorWidget(
        message: vm.errorMessage!,
        onRetry: () => unawaited(vm.loadPointOfPurchases()),
      );
    }
    final query = _search.text.trim().toLowerCase();
    final suppliers = _filterOptions([
      for (final record in vm.records)
        _supplierName(record.supplierName, record.supplierId),
      _supplier,
    ]);
    final productTypes = _filterOptions([
      for (final record in vm.records) record.productType,
      _productType,
    ]);
    final records = vm.records
        .where(
          (record) =>
              (_status == null || (record.docStatus ?? 0) == _status) &&
              (_supplier == null ||
                  record.supplierId == _supplier ||
                  _supplierName(record.supplierName, record.supplierId) ==
                      _supplier) &&
              (_productType == null ||
                  record.productType?.trim() == _productType) &&
              [
                record.name,
                record.supplierName,
                record.supplierId,
                record.collectionLocation,
              ].whereType<String>().join(' ').toLowerCase().contains(query),
        )
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: vm.loadPointOfPurchases,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.pageGutter),
        itemCount: loading || records.isEmpty ? 2 : records.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.cardGap),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  controller: _search,
                  hint: 'Search purchases',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final filters = [
                      _filterDropdown(
                        label: 'Supplier name',
                        allLabel: 'All suppliers',
                        value: _supplier,
                        options: suppliers,
                        onSearch: (query) async {
                          final rows = await vm.repository.searchSuppliers(
                            query,
                          );
                          return [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All suppliers'),
                            ),
                            for (final row in rows)
                              DropdownMenuItem<String>(
                                value: '${row['value']}',
                                child: Text(
                                  _supplierLabels['${row['value']}'] =
                                      '${row['title']} (${row['value']})',
                                ),
                              ),
                          ];
                        },
                        onChanged: (value) {
                          String? id = value;
                          for (final record in vm.records) {
                            if (_supplierName(
                                  record.supplierName,
                                  record.supplierId,
                                ) ==
                                value) {
                              id = record.supplierId;
                              break;
                            }
                          }
                          setState(() => _supplier = id);
                          unawaited(vm.filterBySupplier(id));
                        },
                      ),
                      _filterDropdown(
                        label: 'Product type',
                        allLabel: 'All types',
                        value: _productType,
                        options: productTypes,
                        onChanged: (value) =>
                            setState(() => _productType = value),
                      ),
                    ];
                    if (constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(14) > 18) {
                      return Column(
                        children: [
                          filters[0],
                          const SizedBox(height: AppSpacing.cardGap),
                          filters[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: filters[0]),
                        const SizedBox(width: AppSpacing.cardGap),
                        Expanded(child: filters[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.cardGap),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in const <(String, int?)>[
                        ('All', null),
                        ('Draft', 0),
                        ('Submitted', 1),
                        ('Cancelled', 2),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter.$1),
                            selected: _status == filter.$2,
                            onSelected: (_) =>
                                setState(() => _status = filter.$2),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  '${records.length} recent ${records.length == 1 ? 'purchase' : 'purchases'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Search and filters apply to the latest 50 records.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    vm.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            );
          }
          if (loading) return const PurchaseListSkeleton();
          if (records.isEmpty) {
            return AppEmptyState(
              icon: AppIconName.purchase,
              title: vm.records.isEmpty
                  ? 'No purchases found'
                  : 'No matching purchases',
              description: vm.records.isEmpty
                  ? 'Your purchase records will appear here.'
                  : 'Try another search, supplier, product type or status.',
            );
          }
          final record = records[index - 1];
          return AppPurchaseCard(
            record: record,
            onTap: () => context.pushNamedOnce(
              RouteNames.pointOfPurchaseDetail,
              pathParameters: {'documentName': record.name},
            ),
          );
        },
      ),
    );
  }

  String? _supplierName(String? name, String? id) =>
      name?.trim().isNotEmpty == true ? name!.trim() : id?.trim();

  List<String> _filterOptions(Iterable<String?> values) =>
      values
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  Widget _filterDropdown({
    required String label,
    required String allLabel,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    Future<List<DropdownMenuItem<String>>> Function(String)? onSearch,
  }) => AppDropdown<String>(
    label: label,
    value: value ?? '',
    onSearch: onSearch,
    items: [
      DropdownMenuItem(
        value: '',
        child: Text(allLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      for (final option in options)
        DropdownMenuItem(
          value: option,
          child: Text(
            _supplierLabels[option] ?? option,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
    onChanged: (value) => onChanged(value == '' ? null : value),
  );
}
