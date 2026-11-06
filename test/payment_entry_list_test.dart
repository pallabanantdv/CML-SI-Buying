import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_payment_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/payment_entry_list_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/payment_entry_list_screen.dart';

Map<String, dynamic> payment(int status) => {
  'name': 'ACC-PAY-1',
  'docstatus': status,
  'party_type': 'Supplier',
  'payment_type': 'Pay',
  'party': 'SUP-1',
  'paid_amount': 100,
  'paid_from_account_currency': 'SBD',
};

class ListRepository extends SupplierPaymentRepository {
  ListRepository()
    : super(
        FrappeResourceApi(
          ApiClient(
            DioClient(dio: Dio(BaseOptions(baseUrl: 'https://erp.example'))),
          ),
        ),
      );
  final result = Completer<Map<String, dynamic>>();
  int calls = 0;
  @override
  Future<List<Map<String, dynamic>>> entries({
    int offset = 0,
    int? status,
  }) async => [payment(0)];
  @override
  Future<Map<String, dynamic>> submit(String name) {
    calls++;
    return result.future;
  }
}

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(dynamic value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test(
    'repository lists supplier payments with status and pagination',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
      addTearDown(dio.close);
      late RequestOptions captured;
      dio.httpClientAdapter = Adapter((request) {
        captured = request;
        return body({
          'data': [payment(0)],
        });
      });
      final repository = SupplierPaymentRepository(
        FrappeResourceApi(ApiClient(DioClient(dio: dio))),
      );
      expect(await repository.entries(offset: 50, status: 0), hasLength(1));
      expect(captured.path, '/api/resource/Payment%20Entry');
      expect(jsonDecode(captured.queryParameters['filters'] as String), [
        ['party_type', '=', 'Supplier'],
        ['payment_type', '=', 'Pay'],
        ['docstatus', '=', 0],
      ]);
      expect(captured.queryParameters['limit_start'], 50);
    },
  );
  test('submission sends fresh document through submit lifecycle and rejects non-drafts', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
    addTearDown(dio.close);
    var status = 0;
    final requests = <RequestOptions>[];
    dio.httpClientAdapter = Adapter((request) {
      requests.add(request);
      if (request.method == 'GET') return body({'message': payment(status)});
      expect(request.path, '/api/method/frappe.client.submit');
      expect(
        jsonDecode((request.data as Map)['doc'] as String)['docstatus'],
        0,
      );
      return body({'message': payment(1)});
    });
    final repository = SupplierPaymentRepository(
      FrappeResourceApi(ApiClient(DioClient(dio: dio))),
    );
    expect((await repository.submit('ACC-PAY-1'))['docstatus'], 1);
    expect(requests.map((r) => r.method), ['GET', 'POST']);
    requests.clear();
    status = 1;
    await expectLater(
      repository.submit('ACC-PAY-1'),
      throwsA(isA<AppException>()),
    );
    expect(requests.map((r) => r.method), ['GET']);
  });
  test(
    'draft stays unchanged until confirmed and duplicate submission is blocked',
    () async {
      final repository = ListRepository();
      final vm = PaymentEntryListViewModel(repository);
      addTearDown(vm.dispose);
      await vm.load();
      final pending = vm.submit('ACC-PAY-1');
      expect(vm.records.single['docstatus'], 0);
      expect(await vm.submit('ACC-PAY-1'), isFalse);
      expect(repository.calls, 1);
      repository.result.complete(payment(1));
      expect(await pending, isTrue);
      expect(vm.records.single['docstatus'], 1);
      expect(await vm.submit('ACC-PAY-1'), isFalse);
    },
  );
  test(
    'failed submission preserves draft and shows server validation error',
    () async {
      final repository = ListRepository();
      final vm = PaymentEntryListViewModel(repository);
      addTearDown(vm.dispose);
      await vm.load();
      final pending = vm.submit('ACC-PAY-1');
      repository.result.completeError(
        const AppException('Submit permission required'),
      );
      expect(await pending, isFalse);
      expect(vm.records.single['docstatus'], 0);
      expect(vm.error, 'Submit permission required');
      expect(vm.submittingName, isNull);
    },
  );
  test('confirmed entry leaves the Draft filter', () async {
    final repository = ListRepository();
    final vm = PaymentEntryListViewModel(repository);
    addTearDown(vm.dispose);
    await vm.filter(0);
    final pending = vm.submit('ACC-PAY-1');
    repository.result.complete(payment(1));
    expect(await pending, isTrue);
    expect(vm.records, isEmpty);
  });
  testWidgets(
    'draft Submit button becomes Submitted after server confirmation',
    (tester) async {
      final repository = ListRepository();
      final vm = PaymentEntryListViewModel(repository);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PaymentEntryListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(vm.records.single['docstatus'], 0);
      repository.result.complete(payment(1));
      await tester.pumpAndSettle();
      expect(find.text('Submit'), findsNothing);
      expect(vm.records.single['docstatus'], 1);
      expect(find.text('Payment entry ACC-PAY-1 submitted'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
}
