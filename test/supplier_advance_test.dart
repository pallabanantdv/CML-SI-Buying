import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/constants/api_endpoints.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_method_api.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/supplier_advance.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/create_point_of_purchase_screen.dart';
import 'package:cml_si_buying/shared/widgets/app_dropdown.dart';
import 'package:cml_si_buying/shared/widgets/app_text_field.dart';

import 'mobile_ui_test.dart' as fixtures;

const firstReference = 'CAML-PAY-2026-05446';
const secondReference = 'CAML-PAY-2026-05455';
final sample = [
  SupplierAdvance.fromJson({
    'name': firstReference,
    'paid_amount': 3000.0,
    'unallocated_amount': 3000.0,
  }),
  SupplierAdvance.fromJson({
    'name': secondReference,
    'paid_amount': 4000.0,
    'unallocated_amount': 4000.0,
  }),
];

class Advances extends fixtures.PurchaseData {
  List<SupplierAdvance> result = sample;
  final pending = <String, Completer<List<SupplierAdvance>>>{};
  bool delayed = false;
  int advanceCalls = 0;
  @override
  Future<List<SupplierAdvance>> getSupplierAdvances(String supplier) {
    advanceCalls++;
    return delayed
        ? (pending[supplier] ??= Completer()).future
        : Future.value(result);
  }

  @override
  Future<List<Map<String, dynamic>>> getSupplierOptions() async => [
    ...(await super.getSupplierOptions()),
    {'value': 'S2', 'title': 'Supplier Two', 'label': 'Supplier Two'},
  ];
}

class AdvanceAdapter implements HttpClientAdapter {
  dynamic response;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('repository calls GET method with selected supplier and preserves response order', () async {
    final adapter = AdvanceAdapter()
      ..response = {
        'message': [
          {
            'name': firstReference,
            'paid_amount': 3000,
            'unallocated_amount': '3000.00',
          },
          {
            'name': secondReference,
            'paid_amount': 4000,
            'unallocated_amount': 4000,
          },
        ],
      };
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = adapter;
    final api = ApiClient(DioClient(dio: dio));
    final repo = PointOfPurchaseRepository(
      FrappeResourceApi(api),
      methods: FrappeMethodApi(api),
    );
    final result = await repo.getSupplierAdvances('CAMLSCC-519');
    expect(adapter.request!.method, 'GET');
    expect(
      adapter.request!.path,
      '/api/method/${ApiEndpoints.supplierAdvance}',
    );
    expect(adapter.request!.queryParameters, {'supplier': 'CAMLSCC-519'});
    expect(result.map((row) => row.name), [firstReference, secondReference]);
    expect(result.map((row) => row.unallocatedAmount), [3000, 4000]);
    adapter.response = {'message': []};
    expect(await repo.getSupplierAdvances('S2'), isEmpty);
    for (final invalid in [
      null,
      {},
      [42],
      [
        {'name': 'bad', 'paid_amount': 1},
      ],
    ]) {
      adapter.response = {'message': invalid};
      await expectLater(
        repo.getSupplierAdvances('S2'),
        throwsA(isA<AppException>()),
      );
    }
    dio.close();
  });

  test(
    '7000 available; deductions consume only needed records in API order',
    () async {
      final vm = PointOfPurchaseViewModel(Advances());
      await vm.loadSupplierAdvances('CAMLSCC-519');
      expect(vm.availableAdvance, 7000);
      for (final entry in <String, List<double>>{
        '': [],
        '0': [],
        '2000': [2000],
        '3000': [3000],
        '5000': [3000, 2000],
        '7000': [3000, 4000],
        '3000.01': [3000, 0.01],
      }.entries) {
        final rows = vm.allocateSupplierAdvances(entry.key);
        expect(rows.map((row) => row.allocatedAmount), entry.value);
        if (rows.isNotEmpty) expect(rows.first.advance.name, firstReference);
      }
      final payload = vm
          .allocateSupplierAdvances('5000')
          .map((row) => row.toJson())
          .toList();
      expect(payload, [
        {
          'reference_name': firstReference,
          'remarks': '',
          'advance_amount': 3000.0,
          'allocated_amount': 3000.0,
        },
        {
          'reference_name': secondReference,
          'remarks': '',
          'advance_amount': 4000.0,
          'allocated_amount': 2000.0,
        },
      ]);
      for (final invalid in [
        '7000.01',
        '-1',
        'NaN',
        'Infinity',
        'abc',
        '0.001',
        '1e308',
      ]) {
        expect(
          vm.validateAdvanceDeduction(invalid),
          isNotNull,
          reason: invalid,
        );
        expect(vm.allocateSupplierAdvances(invalid), isEmpty);
      }
      vm.dispose();
    },
  );

  test('cent allocations have no floating-point remainder and skip exhausted advances', () async {
    final repo = Advances()
      ..result = [
        const SupplierAdvance(name: 'zero', paidMinor: 1, unallocatedMinor: 0),
        const SupplierAdvance(name: 'one', paidMinor: 10, unallocatedMinor: 10),
        const SupplierAdvance(name: 'two', paidMinor: 20, unallocatedMinor: 20),
      ];
    final vm = PointOfPurchaseViewModel(repo);
    await vm.loadSupplierAdvances('S');
    expect(vm.availableAdvance, 0.3);
    final rows = vm.allocateSupplierAdvances('0.30');
    expect(rows.map((row) => row.advance.name), ['one', 'two']);
    expect(rows.fold<int>(0, (sum, row) => sum + row.allocatedMinor), 30);
    vm.dispose();
  });

  test('rapid supplier changes discard old responses; same request deduplicates; errors retry', () async {
    final repo = Advances()..delayed = true;
    final vm = PointOfPurchaseViewModel(repo);
    final first = vm.loadSupplierAdvances('S1');
    await vm.loadSupplierAdvances('S1');
    await vm.loadSupplierAdvances('S1', force: true);
    expect(repo.advanceCalls, 1);
    final second = vm.loadSupplierAdvances('S2');
    repo.pending['S1']!.complete(sample);
    await first;
    expect(vm.isLoadingSupplierAdvances, isTrue);
    expect(vm.availableAdvance, 0);
    repo.pending['S2']!.completeError(const AppException('Offline'));
    await second;
    expect(vm.supplierAdvancesError, 'Offline');
    expect(vm.validateAdvanceDeduction('1'), isNotNull);
    repo.pending['S2'] = Completer();
    final retry = vm.loadSupplierAdvances('S2');
    repo.pending['S2']!.complete([sample.last]);
    await retry;
    expect(vm.availableAdvance, 4000);
    expect(vm.supplierAdvancesError, isNull);
    await vm.loadSupplierAdvances('S2');
    expect(repo.advanceCalls, 3);
    vm.clearSupplierAdvances();
    expect(vm.availableAdvance, 0);
    expect(vm.allocateSupplierAdvances('1'), isEmpty);
    vm.dispose();
  });

  for (final reset in [false, true]) {
    test(
      'outstanding advances ignore ${reset ? 'session reset' : 'disposal'}',
      () async {
        final repo = Advances()..delayed = true;
        final vm = PointOfPurchaseViewModel(repo);
        final load = vm.loadSupplierAdvances('S1');
        if (reset) {
          vm.resetSession();
        } else {
          vm.dispose();
        }
        repo.pending['S1']!.complete(sample);
        await load;
        expect(vm.availableAdvance, 0);
        if (reset) vm.dispose();
      },
    );
  }

  testWidgets(
    'form totals balances, creates only used rows, validates excess, clears on supplier change',
    (tester) async {
      tester.view.physicalSize = const Size(360, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = Advances();
      final vm = PointOfPurchaseViewModel(repo);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CreatePointOfPurchaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> select(String option) async {
        final field = find.byWidgetPredicate(
          (w) => w is AppDropdown<String> && w.label == 'Supplier Code *',
        );
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }

      Future<void> deduct(String value) async {
        final field = find.byWidgetPredicate(
          (w) => w is AppTextField && w.label == r'Advances Deduction ($)',
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      await select('Supplier One');
      expect(vm.availableAdvance, 7000);
      await deduct('5000');
      expect(find.text('7000.00'), findsOneWidget);
      await tester.ensureVisible(find.text('Advance Table'));
      await tester.pumpAndSettle();
      var table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.rows.length, 2);
      expect((table.rows[0].cells.last.child as Text).data, r'$ 3,000.00');
      expect((table.rows[1].cells.last.child as Text).data, r'$ 2,000.00');
      await deduct('2000');
      table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.rows.length, 1);
      expect(find.text(secondReference), findsNothing);
      await deduct('7001');
      expect(
        find.text('Deduction cannot exceed the available advance.'),
        findsOneWidget,
      );
      expect(find.byType(DataTable), findsNothing);
      await deduct('2000');
      await select('Supplier Two');
      final deduction = tester.widget<AppTextField>(
        find.byWidgetPredicate(
          (w) => w is AppTextField && w.label == r'Advances Deduction ($)',
        ),
      );
      expect(deduction.controller!.text, isEmpty);
      expect(find.byType(DataTable), findsNothing);
      expect(repo.advanceCalls, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
}
