import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cml_si_buying/config/routes/route_names.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_payment_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_payment_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/create_payment_entry_screen.dart';
import 'package:cml_si_buying/features/supplier/views/add_supplier_screen.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/models/supplier_model.dart';

FrappeResourceApi paymentApi() => FrappeResourceApi(
  ApiClient(DioClient(dio: Dio(BaseOptions(baseUrl: 'https://erp.example')))),
);

class Payments extends SupplierPaymentRepository {
  Payments() : super(paymentApi());
  Map<String, dynamic>? payload;
  Completer<String>? pending;
  @override
  Future<List<Map<String, dynamic>>> companies() async => [
    {'name': 'CAML', 'default_currency': 'SBD'},
  ];
  @override
  Future<List<Map<String, dynamic>>> suppliers() async => [
    {'name': 'SUP-1', 'supplier_name': 'Supplier A'},
  ];
  @override
  Future<List<Map<String, dynamic>>> modes() async => [
    {'name': 'Cash', 'type': 'Cash'},
  ];
  @override
  Future<List<Map<String, dynamic>>> accounts(String company) async => [
    {'name': 'Cash', 'account_type': 'Cash', 'account_currency': 'SBD'},
    {'name': 'Bank', 'account_type': 'Bank', 'account_currency': 'SBD'},
    {'name': 'Payable', 'account_type': 'Payable', 'account_currency': 'SBD'},
  ];
  @override
  Future<List<Map<String, dynamic>>> invoices(
    String company,
    String supplier,
    String currency,
  ) async => [
    {
      'name': 'INV-1',
      'outstanding_amount': 50,
      'grand_total': 100,
      'credit_to': 'Payable',
    },
    {
      'name': 'INV-2',
      'outstanding_amount': 70,
      'grand_total': 100,
      'credit_to': 'Other Account',
    },
  ];
  @override
  Future<String> create(Map<String, dynamic> fields) async {
    payload = fields;
    return pending == null ? 'ACC-PAY-2026-1' : pending!.future;
  }
}

Future<SupplierPaymentViewModel> ready(Payments repository) async {
  final vm = SupplierPaymentViewModel(repository);
  await vm.initialize();
  await vm.selectCompany('CAML');
  vm.supplier = 'SUP-1';
  vm.mode = 'Cash';
  vm.paidFrom = 'Cash';
  vm.paidTo = 'Payable';
  return vm;
}

Future<String?> save(
  SupplierPaymentViewModel vm, {
  double amount = 100,
  double received = 100,
  double allocated = 0,
}) => vm.save(
  date: '2026-11-05',
  amount: amount,
  received: received,
  sourceRate: 1,
  targetRate: 1,
  reference: '',
  referenceDate: '',
  remarks: '',
  allocated: allocated,
);

class PaymentAdapter implements HttpClientAdapter {
  PaymentAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => respond(request);
  @override
  void close({bool force = false}) {}
}

class Directory extends SupplierRepository {
  Directory() : super(paymentApi());
  @override
  Future<List<SupplierModel>> getSuppliers() async => [];
}

void main() {
  testWidgets('directory Payment Entry button opens the payment route', (
    tester,
  ) async {
    final vm = SupplierViewModel(Directory());
    final router = GoRouter(
      initialLocation: '/suppliers',
      routes: [
        GoRoute(
          path: '/suppliers',
          builder: (_, _) => const AddSupplierScreen(),
        ),
        GoRoute(
          path: '/payment-entry',
          name: RouteNames.createPaymentEntry,
          builder: (_, _) => const Scaffold(body: Text('Payment form')),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payment Entry'));
    await tester.pumpAndSettle();
    expect(find.text('Payment form'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Payment Entry'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    vm.dispose();
  });
  test(
    'supplier advance saves a balanced draft with correct ERP field names',
    () async {
      final repository = Payments();
      final vm = await ready(repository);
      addTearDown(vm.dispose);
      expect(await save(vm), 'ACC-PAY-2026-1');
      expect(repository.payload, containsPair('payment_type', 'Pay'));
      expect(repository.payload, containsPair('party_type', 'Supplier'));
      expect(repository.payload, containsPair('party', 'SUP-1'));
      expect(repository.payload, containsPair('docstatus', 0));
      expect(repository.payload!['references'], isEmpty);
      expect(repository.payload!['base_paid_amount'], 100);
      expect(repository.payload!['paid_from_account_currency'], 'SBD');
    },
  );
  test('invalid amounts, unbalanced amounts and missing bank references never call save API', () async {
    final repository = Payments();
    final vm = await ready(repository);
    addTearDown(vm.dispose);
    expect(await save(vm, amount: double.nan), isNull);
    expect(await save(vm, received: 10), isNull);
    vm.paidFrom = 'Bank';
    expect(await save(vm), isNull);
    expect(vm.error, contains('bank reference'));
    expect(repository.payload, isNull);
  });
  test(
    'invoice allocation filters account and cannot exceed outstanding',
    () async {
      final repository = Payments();
      final vm = await ready(repository);
      addTearDown(vm.dispose);
      await vm.loadInvoices();
      expect(vm.invoices.map((row) => row['name']), ['INV-1']);
      vm.invoice = 'INV-1';
      expect(await save(vm, allocated: 60), isNull);
      expect(await save(vm, allocated: 40), isNotNull);
      expect(
        (repository.payload!['references'] as List).single,
        containsPair('reference_name', 'INV-1'),
      );
      expect(
        (repository.payload!['references'] as List).single,
        containsPair('allocated_amount', 40),
      );
    },
  );
  test('duplicate save is blocked and changing company clears accounts and references', () async {
    final repository = Payments()..pending = Completer<String>();
    final vm = await ready(repository);
    addTearDown(vm.dispose);
    final pending = save(vm);
    expect(await save(vm), isNull);
    repository.pending!.complete('ACC-PAY-1');
    await pending;
    vm.invoice = 'INV-1';
    await vm.selectCompany('CAML-2');
    expect(vm.paidFrom, isNull);
    expect(vm.paidTo, isNull);
    expect(vm.invoice, isNull);
  });
  test('repository creates a real Payment Entry draft through existing resource API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
    addTearDown(dio.close);
    dio.httpClientAdapter = PaymentAdapter((request) {
      expect(request.method, 'POST');
      expect(request.path, '/api/resource/Payment%20Entry');
      expect(request.data, containsPair('party_type', 'Supplier'));
      return ResponseBody.fromString(
        jsonEncode({
          'data': {'name': 'ACC-PAY-1', 'docstatus': 0},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final repository = SupplierPaymentRepository(
      FrappeResourceApi(ApiClient(DioClient(dio: dio))),
    );
    expect(
      await repository.create({
        'party_type': 'Supplier',
        'party': 'SUP-1',
        'docstatus': 0,
      }),
      'ACC-PAY-1',
    );
  });
  testWidgets('payment screen loads options and validates before saving', (
    tester,
  ) async {
    final repository = Payments();
    final vm = SupplierPaymentViewModel(repository);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreatePaymentEntryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Supplier payment entry'), findsOneWidget);
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(repository.payload, isNull);
    expect(find.text('Select company.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
