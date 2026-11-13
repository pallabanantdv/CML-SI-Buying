import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/supplier_advance.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/supplier_details_screen.dart';

import 'supplier_details_test.dart' as fixtures;

class _Suppliers extends fixtures.Suppliers {
  final advances = <String, Completer<List<SupplierAdvance>>>{};
  @override
  Future<List<SupplierAdvance>> getSupplierAdvances(String supplier) =>
      (advances[supplier] ??= Completer()).future;
  @override
  Future<Map<String, dynamic>> getSupplier(String name) async => {
    'name': name,
    'supplier_name': 'Supplier A',
  };
}

SupplierAdvance _advance(String name, int minor) =>
    SupplierAdvance(name: name, paidMinor: 10000, unallocatedMinor: minor);

void main() {
  test('details sum the unallocated advances and ignore stale suppliers and sessions', () async {
    final repository = _Suppliers();
    final vm = SupplierViewModel(repository);
    addTearDown(vm.dispose);
    final first = vm.loadSupplierAdvance('A');
    final second = vm.loadSupplierAdvance('B');
    repository.advances['B']!.complete([
      _advance('PAY-1', 10001),
      _advance('PAY-2', 24),
    ]);
    await second;
    repository.advances['A']!.complete([_advance('PAY-OLD', 90000)]);
    await first;
    expect(vm.advanceSupplierId, 'B');
    expect(vm.availableAdvance, 100.25);
    final third = vm.loadSupplierAdvance('C');
    vm.resetSession();
    repository.advances['C']!.complete([_advance('PAY-C', 2500)]);
    await third;
    expect(vm.availableAdvance, isNull);
    expect(vm.advanceSupplierId, isNull);
  });

  test(
    'advance failure stays distinct from zero and retry can return zero',
    () async {
      final repository = _Suppliers();
      final vm = SupplierViewModel(repository);
      addTearDown(vm.dispose);
      final failed = vm.loadSupplierAdvance('A');
      repository.advances['A']!.completeError(StateError('offline'));
      await failed;
      expect(vm.availableAdvance, isNull);
      expect(vm.advanceError, isNotNull);
      repository.advances.remove('A');
      final retry = vm.loadSupplierAdvance('A');
      repository.advances['A']!.complete([]);
      await retry;
      expect(vm.availableAdvance, 0);
      expect(vm.advanceError, isNull);
    },
  );

  testWidgets(
    'supplier details show the available advance even if the card fails',
    (tester) async {
      final repository = _Suppliers();
      final vm = SupplierViewModel(repository);
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SupplierDetailsScreen(supplierId: 'A'),
          ),
        ),
      );
      await tester.pump();
      repository.advances['A']!.complete([_advance('PAY-1', 3525)]);
      await tester.pumpAndSettle();
      expect(find.text('Available advance (\$)'), findsOneWidget);
      expect(find.text('35.25'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
