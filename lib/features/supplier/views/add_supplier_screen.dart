import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_page_banner.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/supplier_model.dart';
import '../viewmodels/supplier_viewmodel.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<SupplierViewModel>().loadSuppliers());
  }

  @override
  Widget build(BuildContext context) => Consumer<SupplierViewModel>(
    builder: (context, viewModel, _) => Scaffold(
      appBar: AppAppBar(title: AppHeaderTitle(title: viewModel.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.supplierDirectoryMaxWidth,
          ),
          child: _buildContent(context, viewModel),
        ),
      ),
    ),
  );

  Widget _buildContent(BuildContext context, SupplierViewModel viewModel) {
    if (viewModel.isLoading && viewModel.suppliers.isEmpty) {
      return const AppLoader(label: 'Loading suppliers...');
    }
    if (viewModel.errorMessage != null && viewModel.suppliers.isEmpty) {
      return AppErrorWidget(
        message: viewModel.errorMessage!,
        onRetry: () => unawaited(viewModel.loadSuppliers()),
      );
    }

    final suppliers = viewModel.filteredSuppliers;
    return RefreshIndicator(
      onRefresh: viewModel.loadSuppliers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.pageGutter),
        itemCount: suppliers.isEmpty ? 3 : suppliers.length + 2,
        separatorBuilder: (_, index) => SizedBox(
          height: index == 0 ? AppSpacing.medium : AppSpacing.standard,
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SupplierHeading(
              count: suppliers.length,
              totalCount: viewModel.suppliers.length,
            );
          }
          if (index == 1) {
            return _searchAndAddSupplier(context, viewModel);
          }
          if (index == 2 && suppliers.isEmpty) {
            return SizedBox(
              height: 260,
              child: AppEmptyState(
                icon: AppIconName.supplier,
                title: viewModel.suppliers.isEmpty
                    ? 'No suppliers found'
                    : 'No matching suppliers',
                description: viewModel.suppliers.isEmpty
                    ? 'Supplier records will appear here when they are available.'
                    : 'Try another name, supplier ID, or location.',
              ),
            );
          }
          return _SupplierCard(supplier: suppliers[index - 2]);
        },
      ),
    );
  }

  Widget _searchAndAddSupplier(
    BuildContext context,
    SupplierViewModel viewModel,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final compactAction = constraints.maxWidth < 300;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AppCard(
              tone: AppCardTone.info,
              showAccentBar: true,
              padding: const EdgeInsets.all(AppSpacing.small),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Search suppliers',
                      hint: 'Name, ID, location, or contact',
                      prefixIcon: AppSvgIcon(
                        icon: AppIconName.search,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: viewModel.search,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Tooltip(
                    message: 'Add supplier',
                    child: AppButton(
                      label: compactAction ? 'Add' : 'Add',
                      icon: AppIconName.add,
                      expand: false,
                      onPressed: () async {
                        final created = await context.pushNamed<bool>(
                          RouteNames.createSupplier,
                        );
                        if (created == true && context.mounted) {
                          await viewModel.loadSuppliers();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
        ],
      );
    },
  );
}

class _SupplierHeading extends StatelessWidget {
  const _SupplierHeading({required this.count, required this.totalCount});

  final int count;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final countLabel = count == totalCount
        ? '$count ${count == 1 ? 'supplier' : 'suppliers'}'
        : '$count of $totalCount';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: AppPageBanner(
        eyebrow: 'Buying workspace',
        title: 'Supplier directory',
        description: 'Find and manage registered suppliers.',
        icon: AppIconName.supplier,
        badge: countLabel,
      ),
    );
  }
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
    final initial = supplier.name.trim().isEmpty
        ? '?'
        : supplier.name.trim()[0].toUpperCase();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.standard),
      tone: supplier.isDisabled
          ? AppCardTone.error
          : isActive
          ? AppCardTone.success
          : AppCardTone.warning,
      showAccentBar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  initial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(supplier.id, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              AppStatusBadge(label: status, color: statusColor),
            ],
          ),
          if (supplier.location != null ||
              supplier.type != null ||
              supplier.group != null) ...[
            const SizedBox(height: AppSpacing.standard),
            Wrap(
              spacing: AppSpacing.large,
              runSpacing: AppSpacing.medium,
              children: [
                if (supplier.type != null)
                  _SupplierFact(label: 'Type', value: supplier.type!),
                if (supplier.group != null)
                  _SupplierFact(label: 'Group', value: supplier.group!),
                if (supplier.location != null)
                  _SupplierFact(label: 'Location', value: supplier.location!),
              ],
            ),
          ],
          if (supplier.phone != null || supplier.email != null) ...[
            const SizedBox(height: AppSpacing.standard),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            const SizedBox(height: AppSpacing.medium),
            if (supplier.phone != null)
              _SupplierContact(icon: AppIconName.phone, value: supplier.phone!),
            if (supplier.phone != null && supplier.email != null)
              const SizedBox(height: AppSpacing.small),
            if (supplier.email != null)
              _SupplierContact(icon: AppIconName.email, value: supplier.email!),
          ],
        ],
      ),
    );
  }
}

class _SupplierFact extends StatelessWidget {
  const _SupplierFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(AppDimensions.badgeRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xSmall),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
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
