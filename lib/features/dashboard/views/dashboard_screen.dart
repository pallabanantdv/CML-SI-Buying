import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_navigation.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../widgets/dashboard_skeleton.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../models/dashboard_data.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/dashboard_purchase_chart.dart';
import '../widgets/dashboard_revenue_chart.dart';
import '../widgets/dashboard_kpi_card.dart';
import '../widgets/dashboard_product_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTimeRange? _purchaseDateRange;

  DateTimeRange? _responseDateRange() {
    final summary = context.read<DashboardViewModel>().data?.invoiceSummary;
    final from = DateTime.tryParse(summary?.fromDate ?? '');
    final to = DateTime.tryParse(summary?.toDate ?? '');
    return from != null && to != null && !from.isAfter(to)
        ? DateTimeRange(start: from, end: to)
        : null;
  }

  Future<void> _selectPurchaseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _purchaseDateRange ?? _responseDateRange(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (!mounted || range == null) return;
    await context.read<DashboardViewModel>().setDateRange(
      range.start,
      range.end,
    );
    if (mounted) setState(() => _purchaseDateRange = range);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<DashboardViewModel>().ensureLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthViewModel>().user?.fullName?.trim();
    return Scaffold(
      appBar: const AppAppBar(title: AppHeaderTitle(title: 'CMAL BI Buying')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.contentMaxWidth,
            ),
            child: Consumer<DashboardViewModel>(
              builder: (context, vm, _) => RefreshIndicator(
                onRefresh: vm.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Purchase Overview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        // if (vm.data?.isDemo == true)
                        //   AppStatusBadge(
                        //     label: 'Demo data',
                        //     color: context.appColors.info,
                        //   ),
                      ],
                    ),
                    if (name != null && name.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Welcome, $name',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (vm.data == null &&
                        (vm.isLoading || vm.errorMessage == null))
                      const DashboardSkeleton()
                    else if (vm.data == null && vm.errorMessage != null)
                      AppErrorWidget(
                        message: vm.errorMessage!,
                        onRetry: () => unawaited(vm.refresh()),
                      )
                    else if (vm.data != null) ...[
                      if (vm.errorMessage != null) ...[
                        AppErrorWidget(
                          message: vm.errorMessage!,
                          onRetry: () => unawaited(vm.refresh()),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // if (vm.data!.isDemo) ...[
                      //   Text(
                      //     'Sample figures only · not live ERP data',
                      //     style: Theme.of(context).textTheme.bodySmall,
                      //   ),
                      //   const SizedBox(height: 8),
                      // ],
                      if (vm.isEmpty)
                        const AppEmptyState(
                          icon: AppIconName.purchase,
                          title: 'No purchases in this period',
                          description:
                              'Pull down to refresh the purchase overview.',
                        ),
                      if (vm.isLoading) const LinearProgressIndicator(),
                      SkeletonReveal(
                        loading: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _overview(context, vm.data!),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Quick actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _ResponsivePair(
                      children: [
                        AppButton(
                          label: 'Add purchase',
                          icon: AppIconName.add,
                          onPressed: () => context.pushNamedOnce(
                            RouteNames.createPointOfPurchase,
                          ),
                        ),
                        AppButton(
                          label: 'View suppliers',
                          icon: AppIconName.supplier,
                          variant: AppButtonVariant.outlined,
                          onPressed: () =>
                              context.goNamed(RouteNames.addSupplier),
                        ),
                        AppButton(
                          label: 'Payment entry',
                          icon: AppIconName.add,
                          variant: AppButtonVariant.outlined,
                          onPressed: () => context.pushNamedOnce(
                            RouteNames.createPaymentEntry,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _overview(BuildContext context, DashboardData data) => [
    if (data.invoiceSummary?.currencyWarning case final String warning)
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(warning)),
    DashboardSummaryCard(
      data: data,
      dateRange: _purchaseDateRange,
      onSelectDateRange: context.read<DashboardViewModel>().isLoading
          ? null
          : _selectPurchaseDateRange,
      onClearDateRange: () async {
        await context.read<DashboardViewModel>().setDateRange(null, null);
        if (mounted) setState(() => _purchaseDateRange = null);
      },
    ),
    const SizedBox(height: 8),
    // _ResponsivePair(
    //   children: [
    //     DashboardKpiCard(
    //       label: 'Draft purchases',
    //       value: data.summary.draftCount,
    //       icon: AppIconName.purchase,
    //     ),
    //     DashboardKpiCard(
    //       label: 'Submitted purchases',
    //       value: data.summary.submittedCount,
    //       icon: AppIconName.success,
    //     ),
    //   ],
    // ),
    // const SizedBox(height: 12),
    // Text(
    //   'Products · ${data.summary.productCount}',
    //   style: Theme.of(context).textTheme.titleMedium,
    // ),

    _ResponsivePair(
      children: [
        for (final product in data.products)
          DashboardProductCard(
            product: product,
            quantity: data.quantityFor(product.id),
            amount: data.amountFor(product.id),
            currencySymbol: data.currencySymbol,
          ),
      ],
    ),

    const SizedBox(height: 8),
    AppCard(
      title: 'Invoice overview',
      // subtitle: data.periodLabel,
      child: _ResponsivePair(
        children: [
          DashboardKpiCard(
            label: 'Total invoices',
            value: data.summary.transactionCount,
            icon: AppIconName.purchase,
          ),
          DashboardKpiCard(
            label: 'Paid invoices',
            value: data.invoiceSummary?.paidCount ?? 0,
            icon: AppIconName.success,
          ),
          DashboardKpiCard(
            label: 'Unpaid invoices',
            value: data.invoiceSummary?.unpaidCount ?? 0,
            icon: AppIconName.purchase,
          ),
          DashboardKpiCard(
            label: 'Partly paid invoices',
            value: data.invoiceSummary?.partlyPaidCount ?? 0,
            icon: AppIconName.purchase,
          ),
        ],
      ),
    ),

    const SizedBox(height: 12),
    DashboardPurchaseChart(summary: data.invoiceSummary),
    const SizedBox(height: 12),
    DashboardRevenueChart(revenue: data.revenue),
    const SizedBox(height: 12),

    // const SizedBox(height: 12),
    // Wrap(
    //   alignment: WrapAlignment.spaceBetween,
    //   crossAxisAlignment: WrapCrossAlignment.center,
    //   spacing: 12,
    //   children: [
    //     Text(
    //       'Recent purchases',
    //       style: Theme.of(context).textTheme.titleMedium,
    //     ),
    //     TextButton(
    //       onPressed: () => context.goNamed(RouteNames.pointOfPurchase),
    //       child: const Text('View purchases'),
    //     ),
    //   ],
    // ),
    // for (final purchase in data.recentPurchases)
    //   Padding(
    //     padding: const EdgeInsets.only(bottom: 8),
    //     child: RecentPurchaseTile(
    //       purchase: purchase,
    //       productName: data.productName(purchase.productId),
    //       currencySymbol: data.currencySymbol,
    //       onTap: purchase.documentName == null
    //           ? null
    //           : () => context.pushNamedOnce(
    //               RouteNames.pointOfPurchaseDetail,
    //               pathParameters: {'documentName': purchase.documentName!},
    //             ),
    //     ),
    //   ),
  ];
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(14) <= 21
          ? 2
          : 1;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final child in children)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 8) / columns,
              child: child,
            ),
        ],
      );
    },
  );
}
