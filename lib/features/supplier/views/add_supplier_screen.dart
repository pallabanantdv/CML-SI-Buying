import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigation.dart';

import 'package:provider/provider.dart';

import '../../../core/diagnostics/app_diagnostics.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_card_heading.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../widgets/supplier_list_skeleton.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../models/supplier_model.dart';
import '../viewmodels/supplier_viewmodel.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  late final TextEditingController _searchController;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<SupplierViewModel>().searchQuery,
    );
    AppDiagnostics.write('[$runtimeType] initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SupplierViewModel>().loadSuppliers());
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<SupplierViewModel>(
    builder: (context, viewModel, _) => Scaffold(
      appBar: AppAppBar(
        title: AppHeaderTitle(title: viewModel.title),
        actions: [
          TextButton(
            onPressed: () => context.pushNamedOnce(RouteNames.paymentEntries),
            child: const Text('Payment entries'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.supplierDirectoryMaxWidth,
            ),
            child: SkeletonReveal(
              loading:
                  !viewModel.hasLoaded &&
                  viewModel.suppliers.isEmpty &&
                  (viewModel.isLoading ||
                      (!viewModel.hasLoaded && viewModel.errorMessage == null)),
              child: _buildContent(context, viewModel),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildContent(BuildContext context, SupplierViewModel viewModel) {
    if (AppDiagnostics.enabled) {
      AppDiagnostics.write(
        '[$runtimeType] render loading=${viewModel.isLoading}',
      );
    }
    final loading =
        !viewModel.hasLoaded &&
        viewModel.suppliers.isEmpty &&
        (viewModel.isLoading ||
            (!viewModel.hasLoaded && viewModel.errorMessage == null));
    if (!loading &&
        viewModel.errorMessage != null &&
        !viewModel.hasLoaded &&
        viewModel.suppliers.isEmpty) {
      return AppErrorWidget(
        message: viewModel.errorMessage!,
        onRetry: () => unawaited(viewModel.loadSuppliers()),
      );
    }

    final suppliers = viewModel.filteredSuppliers;
    return RefreshIndicator(
      onRefresh: viewModel.loadSuppliers,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.pageGutter),
        itemCount: loading || suppliers.isEmpty ? 2 : suppliers.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: AppSpacing.cardGap),
        itemBuilder: (context, index) {
          if (index == 0) return _searchAndAddSupplier(context, viewModel);
          if (loading) return const SupplierListSkeleton();
          if (index == 1 && suppliers.isEmpty) {
            return AppEmptyState(
              icon: AppIconName.supplier,
              title: viewModel.suppliers.isEmpty
                  ? 'No suppliers found'
                  : 'No matching suppliers',
              description: viewModel.suppliers.isEmpty
                  ? 'Supplier records will appear here when they are available.'
                  : 'Try another name, supplier ID, or location.',
            );
          }
          return _SupplierCard(supplier: suppliers[index - 1]);
        },
      ),
    );
  }

  Widget _searchAndAddSupplier(
    BuildContext context,
    SupplierViewModel viewModel,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSearchField(
        controller: _searchController,
        hint: 'Search suppliers',
        onChanged: viewModel.search,
      ),
      const SizedBox(height: AppSpacing.cardGap),
      LayoutBuilder(
        builder: (context, constraints) {
          final count = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${viewModel.filteredSuppliers.length} suppliers',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Latest 100 records',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
          final action = AppButton(
            label: 'Add supplier',
            icon: AppIconName.add,
            expand: false,
            onPressed: () async {
              final created = await context.pushNamedOnce<bool>(
                RouteNames.createSupplier,
              );
              if (created == true && context.mounted) {
                AppSnackbar.show(
                  context,
                  'Supplier saved',
                  type: AppMessageType.success,
                );
                await viewModel.loadSuppliers();
              }
            },
          );
          if (constraints.maxWidth < 270 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [count, const SizedBox(height: 8), action],
            );
          }
          return Row(
            children: [
              Expanded(child: count),
              const SizedBox(width: 8),
              action,
            ],
          );
        },
      ),
    ],
  );
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.supplier});

  final SupplierModel supplier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = supplier.isDisabled
        ? 'Disabled'
        : supplier.isOnHold
        ? 'On hold'
        : supplier.isFrozen
        ? 'Frozen'
        : supplier.status ?? 'Active';
    final isActive =
        !supplier.isDisabled &&
        !supplier.isOnHold &&
        !supplier.isFrozen &&
        (supplier.status == null || supplier.status!.toLowerCase() == 'active');
    final statusColor = supplier.isDisabled
        ? theme.extension<AppSemanticColors>()!.error
        : isActive
        ? theme.extension<AppSemanticColors>()!.success
        : theme.extension<AppSemanticColors>()!.warning;
    final description = [
      supplier.type,
      supplier.group,
      supplier.location,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' \u00b7 ');
    return AppCard(
      onTap: () => context.pushNamedOnce(
        RouteNames.supplierDetails,
        pathParameters: {'supplierId': supplier.id},
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardHeading(
            title: supplier.name,
            trailing: AppStatusBadge(label: status, color: statusColor),
          ),
          const SizedBox(height: 2),
          Text(supplier.id, style: theme.textTheme.bodySmall),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Tooltip(
              message: description,
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          if (supplier.phone != null || supplier.email != null) ...[
            const SizedBox(height: 6),
            if (supplier.phone != null)
              _SupplierContact(icon: AppIconName.phone, value: supplier.phone!),
            if (supplier.phone != null && supplier.email != null)
              const SizedBox(height: 4),
            if (supplier.email != null)
              _SupplierContact(icon: AppIconName.email, value: supplier.email!),
          ],
        ],
      ),
    );
  }
}

class _SupplierContact extends StatelessWidget {
  const _SupplierContact({required this.icon, required this.value});

  final AppIconName icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AppSvgIcon(
        icon: icon,
        size: 16,
        color: icon == AppIconName.phone
            ? context.appColors.success
            : context.appColors.info,
      ),
      const SizedBox(width: AppSpacing.small),
      Expanded(
        child: Text(value, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}
