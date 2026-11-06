import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/utils/number_format.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_card_heading.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../viewmodels/payment_entry_list_viewmodel.dart';

class PaymentEntryListScreen extends StatefulWidget {
  const PaymentEntryListScreen({super.key});
  @override
  State<PaymentEntryListScreen> createState() => _PaymentEntryListScreenState();
}

class _PaymentEntryListScreenState extends State<PaymentEntryListScreen> {
  bool _creating = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<PaymentEntryListViewModel>().load());
    });
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
              child: RefreshIndicator(
                onRefresh: () => vm.load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
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
                                    : (_) => unawaited(vm.filter(choice.$2)),
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
                          onPressed: busy ? null : () => unawaited(vm.load()),
                          child: const Text('Refresh'),
                        ),
                      ],
                      if (vm.loading) const LinearProgressIndicator(),
                      if (vm.records.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No payment entries found.'),
                        ),
                      for (final record in vm.records) ...[
                        _entry(vm, record),
                        const SizedBox(height: 12),
                      ],
                      if (vm.hasMore)
                        AppButton(
                          label: 'Load more',
                          isLoading: vm.loadingMore,
                          onPressed: busy || vm.loading
                              ? null
                              : () => vm.load(more: true),
                        ),
                    ],
                  ],
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
