import 'package:cml_si_buying/shared/navigation/animated_branch_container.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/point_of_purchase_model.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_detail_screen.dart';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/supplier/models/supplier_model.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/add_supplier_screen.dart';
import 'package:cml_si_buying/core/network/interceptors/logging_interceptor.dart';

class Suppliers extends SupplierRepository {
  Suppliers()
    : super(
        FrappeResourceApi(
          ApiClient(
            DioClient(dio: Dio(BaseOptions(baseUrl: 'https://example.com'))),
          ),
        ),
      );
  Completer<List<SupplierModel>> pending = Completer();
  int calls = 0;
  @override
  Future<List<SupplierModel>> getSuppliers() {
    calls++;
    return pending.future;
  }
}

class Purchases extends PointOfPurchaseRepository {
  Purchases()
    : super(
        FrappeResourceApi(
          ApiClient(
            DioClient(dio: Dio(BaseOptions(baseUrl: 'https://example.com'))),
          ),
        ),
      );
  final list = Completer<List<PointOfPurchaseModel>>();
  final details = <String, Completer<Map<String, dynamic>>>{};
  int detailCalls = 0;
  @override
  Future<List<PointOfPurchaseModel>> getPointOfPurchases() => list.future;
  @override
  Future<Map<String, dynamic>> getPointOfPurchase(String name) {
    detailCalls++;
    return (details[name] ??= Completer()).future;
  }
}

class BranchProbe extends StatefulWidget {
  const BranchProbe({super.key, required this.onInit});
  final VoidCallback onInit;
  @override
  State<BranchProbe> createState() => _BranchProbeState();
}

class _BranchProbeState extends State<BranchProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  testWidgets('branch visibility preserves subtree identity', (tester) async {
    var initializations = 0;
    final children = [
      BranchProbe(onInit: () => initializations++),
      const SizedBox(),
    ];
    Widget host(int index) => MaterialApp(
      home: AnimatedBranchContainer(currentIndex: index, children: children),
    );
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();
    expect(initializations, 1);
  });

  testWidgets('purchase list and detail render on first completion', (
    tester,
  ) async {
    final repository = Purchases();
    final vm = PointOfPurchaseViewModel(repository);
    Widget host(Widget screen) => ChangeNotifierProvider.value(
      value: vm,
      child: MaterialApp(theme: AppTheme.light, home: screen),
    );
    await tester.pumpWidget(host(const PointOfPurchaseScreen()));
    await tester.pump();
    expect(find.text('Loading purchase records...'), findsOneWidget);
    repository.list.complete([
      PointOfPurchaseModel.fromJson({
        'name': 'POP-1',
        'supplier_name1': 'First purchase',
      }),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('POP-1'), findsOneWidget);
    await tester.pumpWidget(
      host(const PointOfPurchaseDetailScreen(documentName: 'POP-1')),
    );
    await tester.pump();
    expect(find.text('Loading purchase details...'), findsOneWidget);
    await vm.loadPointOfPurchase('POP-1');
    expect(repository.detailCalls, 1);
    repository.details['POP-1']!.complete({
      'name': 'POP-1',
      'supplier_name1': 'First purchase',
    });
    await tester.pumpAndSettle();
    expect(find.text('Loading purchase details...'), findsNothing);
    expect(find.text('POP-1'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  test(
    'detail error retries and older response cannot replace current document',
    () async {
      final repository = Purchases();
      final vm = PointOfPurchaseViewModel(repository);
      final first = vm.loadPointOfPurchase('A');
      final second = vm.loadPointOfPurchase('B');
      repository.details['B']!.completeError(StateError('offline'));
      await second;
      expect(vm.isLoadingDetail, false);
      expect(vm.detailErrorMessage, isNotNull);
      repository.details['B'] = Completer();
      final retry = vm.loadPointOfPurchase('B');
      repository.details['B']!.complete({'name': 'B'});
      await retry;
      repository.details['A']!.complete({'name': 'A'});
      await first;
      expect(vm.selectedRecord?['name'], 'B');
      expect(vm.detailErrorMessage, isNull);
      vm.dispose();
    },
  );

  testWidgets(
    'first visit renders completion without navigation; error retries',
    (tester) async {
      final repository = Suppliers();
      final vm = SupplierViewModel(repository);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AddSupplierScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Loading suppliers...'), findsOneWidget);
      await vm.loadSuppliers(); // In-flight call is deduplicated.
      expect(repository.calls, 1);
      repository.pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load suppliers.'), findsOneWidget);
      repository.pending = Completer();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      repository.pending.complete([
        const SupplierModel(id: 'S1', name: 'First supplier'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('First supplier'), findsOneWidget);
      expect(vm.isLoading, false);
      expect(repository.calls, 2);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );

  test('disposed viewmodel ignores outstanding result', () async {
    final repository = Suppliers();
    final vm = SupplierViewModel(repository);
    final load = vm.loadSuppliers();
    vm.dispose();
    repository.pending.complete([
      const SupplierModel(id: 'S', name: 'Private'),
    ]);
    await load;
    expect(vm.suppliers, isEmpty);
  });

  test(
    'logs redact credentials, business values, nested JSON and URL identifiers',
    () {
      final safe = SafeLoggingInterceptor.sanitize({
        'Authorization': 'Bearer secret',
        'data': [
          {'supplier_name': 'Private', 'net_payable': 100},
        ],
        '_server_messages': '["private error"]',
        'cookie': 'sid=secret',
      }).toString();
      expect(safe, isNot(contains('Private')));
      expect(safe, isNot(contains('secret')));
      expect(safe, isNot(contains('100')));
      expect(safe, isNot(contains('private error')));
      expect(
        SafeLoggingInterceptor.safeUrl(
          Uri.parse(
            'https://user:pass@example.com/api/resource/Supplier/Private?token=secret',
          ),
        ),
        isNot(contains('Private')),
      );
    },
  );
}
