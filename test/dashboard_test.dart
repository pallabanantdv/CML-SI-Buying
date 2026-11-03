import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/features/dashboard/models/dashboard_data.dart';
import 'package:cml_si_buying/features/dashboard/repositories/dashboard_repository.dart';
import 'package:cml_si_buying/features/dashboard/repositories/static_dashboard_repository.dart';
import 'package:cml_si_buying/features/dashboard/viewmodels/dashboard_viewmodel.dart';

class ControlledDashboardRepository implements DashboardRepository {
  int calls = 0;
  Completer<DashboardData> pending = Completer<DashboardData>();
  @override
  Future<DashboardData> getDashboardData() {
    calls++;
    return pending.future;
  }
}

void main() {
  test('demo ledger agrees with summary and both product totals', () async {
    final data = await const StaticDashboardRepository().getDashboardData();
    expect(data.isDemo, true);
    expect(data.products.length, 2);
    expect(data.summary.transactionCount, 8);
    expect(data.summary.totalValue, 24500);
    expect(data.summary.draftCount, 2);
    expect(data.summary.submittedCount, 6);
    expect(data.quantityFor('a'), 120);
    expect(data.quantityFor('b'), 80);
    expect(data.amountFor('a'), 14500);
    expect(data.amountFor('b'), 10000);
    expect(data.recentPurchases.length, 4);
    expect(data.recentPurchases.first.number, 'DEMO-POP-008');
    expect(data.purchases.every((p) => p.documentName == null), true);
    expect(
      data.purchases.every(
        (p) => data.products.any((item) => item.id == p.productId),
      ),
      true,
    );
  });

  test('load deduplicates, caches success and explicitly refreshes', () async {
    final repository = ControlledDashboardRepository();
    final vm = DashboardViewModel(repository);
    final loading = vm.ensureLoaded();
    expect(vm.isLoading, true);
    await vm.ensureLoaded();
    expect(repository.calls, 1);
    final data = await const StaticDashboardRepository().getDashboardData();
    repository.pending.complete(data);
    await loading;
    expect(vm.data, same(data));
    expect(vm.isLoading, false);
    await vm.ensureLoaded();
    expect(repository.calls, 1);
    repository.pending = Completer<DashboardData>();
    final refreshing = vm.refresh();
    expect(vm.data, same(data));
    repository.pending.complete(data);
    await refreshing;
    expect(repository.calls, 2);
    vm.dispose();
  });

  test('failed load retries and empty data is an explicit state', () async {
    final repository = ControlledDashboardRepository();
    final vm = DashboardViewModel(repository);
    final loading = vm.ensureLoaded();
    repository.pending.completeError(StateError('private server details'));
    await loading;
    expect(vm.isLoading, false);
    expect(vm.errorMessage, isNot(contains('private server details')));
    expect(vm.errorMessage, isNotNull);
    repository.pending = Completer<DashboardData>();
    final retry = vm.refresh();
    repository.pending.complete(
      DashboardData(
        periodLabel: 'Empty period',
        currencySymbol: r'$',
        isDemo: false,
        products: [],
        purchases: [],
      ),
    );
    await retry;
    expect(vm.errorMessage, isNull);
    expect(vm.isEmpty, true);
    expect(vm.data!.summary.totalValue, 0);
    vm.dispose();
  });

  test('late load completion after disposal is ignored', () async {
    final repository = ControlledDashboardRepository();
    final vm = DashboardViewModel(repository);
    final loading = vm.refresh();
    vm.dispose();
    repository.pending.complete(
      await const StaticDashboardRepository().getDashboardData(),
    );
    await loading;
    expect(vm.data, isNull);
  });
}
