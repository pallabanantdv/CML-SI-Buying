import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/routes/route_names.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/supplier/models/supplier_model.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/add_supplier_screen.dart';
import 'package:cml_si_buying/features/supplier/views/supplier_details_screen.dart';

class Suppliers extends SupplierRepository {
  Suppliers()
    : super(
        FrappeResourceApi(
          ApiClient(
            DioClient(dio: Dio(BaseOptions(baseUrl: 'https://erp.example'))),
          ),
        ),
      );
  final requests = <String, Completer<Map<String, dynamic>>>{};
  int detailCalls = 0;
  @override
  Future<List<SupplierModel>> getSuppliers() async => const [
    SupplierModel(id: 'SUP/A 1', name: 'North Supplier'),
  ];
  @override
  Future<Map<String, dynamic>> getSupplier(String name) {
    detailCalls++;
    return (requests[name] ??= Completer()).future;
  }
}

void main() {
  testWidgets(
    'supplier card opens full document with custom fields and child rows',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = Suppliers();
      final vm = SupplierViewModel(repository);
      final router = GoRouter(
        initialLocation: '/suppliers',
        routes: [
          GoRoute(
            path: '/suppliers',
            builder: (_, _) => const AddSupplierScreen(),
            routes: [
              GoRoute(
                path: 'details/:supplierId',
                name: RouteNames.supplierDetails,
                builder: (_, state) => SupplierDetailsScreen(
                  supplierId: state.pathParameters['supplierId']!,
                ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('North Supplier'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Supplier details'), findsOneWidget);
      expect(repository.requests.keys, ['SUP/A 1']);
      expect(repository.detailCalls, 1);
      repository.requests['SUP/A 1']!.complete({
        'name': 'SUP/A 1',
        'supplier_name': 'North Supplier',
        'email_id': 'north@example.com',
        'village': 'Coastal Village',
        'tax_id': 'TAX-123',
        'custom_registration': 'REG-123',
        'accounts': [
          {'company': 'CAML', 'account': 'Payables - CAML'},
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('north@example.com'), findsOneWidget);
      expect(find.text('TAX-123'), findsOneWidget);
      expect(find.text('REG-123'), findsOneWidget);
      await tester.tap(find.text('Accounts (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Payables - CAML'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Search suppliers'), findsOneWidget);
      expect(vm.suppliers.single.id, 'SUP/A 1');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      vm.dispose();
    },
  );

  test('older detail responses and previous sessions cannot replace the selected supplier', () async {
    final repository = Suppliers();
    final vm = SupplierViewModel(repository);
    final old = vm.loadSupplier('A');
    final current = vm.loadSupplier('B');
    repository.requests['B']!.complete({'name': 'B'});
    await current;
    repository.requests['A']!.complete({'name': 'A'});
    await old;
    expect(vm.selectedSupplier?['name'], 'B');
    final pending = vm.loadSupplier('C');
    vm.resetSession();
    repository.requests['C']!.complete({'name': 'C'});
    await pending;
    expect(vm.selectedSupplier, isNull);
    expect(vm.selectedSupplierId, isNull);
    vm.dispose();
  });

  test('detail retry deduplicates requests and keeps existing content on refresh failure', () async {
    final repository = Suppliers();
    final vm = SupplierViewModel(repository);
    final first = vm.loadSupplier('A');
    await vm.loadSupplier('A');
    expect(repository.detailCalls, 1);
    repository.requests['A']!.completeError(
      const AppException('Temporary failure'),
    );
    await first;
    expect(vm.detailErrorMessage, 'Temporary failure');
    repository.requests['A'] = Completer();
    final retry = vm.loadSupplier('A');
    repository.requests['A']!.complete({
      'name': 'A',
      'supplier_name': 'Supplier A',
    });
    await retry;
    repository.requests['A'] = Completer();
    final refresh = vm.loadSupplier('A');
    expect(vm.selectedSupplier?['supplier_name'], 'Supplier A');
    repository.requests['A']!.completeError(
      const AppException('Network failed'),
    );
    await refresh;
    expect(vm.selectedSupplier?['supplier_name'], 'Supplier A');
    vm.dispose();
  });
}
