import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/cache/cache_manager.dart';
import 'package:cml_si_buying/core/cache/cache_service.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/connectivity_service.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_method_api.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/point_of_purchase_model.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_detail_screen.dart';

Map<String, dynamic> document(int status) => {
  'doctype': 'Supplier Point Of Purchase',
  'name': 'POP/1',
  'docstatus': status,
  'supplier_name1': 'Supplier A',
  'net_payable': 100,
  'supplier_pop_item': [
    {'item': 'Copra', 'qty': 1},
  ],
};
FrappeResourceApi resources() => FrappeResourceApi(
  ApiClient(DioClient(dio: Dio(BaseOptions(baseUrl: 'https://erp.example')))),
);

class SubmitRepository extends PointOfPurchaseRepository {
  SubmitRepository({this.status = 0}) : super(resources());
  int status;
  int calls = 0;
  final result = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> getPointOfPurchase(String name) async =>
      document(status);
  @override
  Future<List<PointOfPurchaseModel>> getPointOfPurchases({int offset = 0}) async => [
    PointOfPurchaseModel.fromJson(document(status)),
  ];
  @override
  Future<Map<String, dynamic>> submitPointOfPurchase(String name) {
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
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(dynamic body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'draft button submits once, shows confirmed status and disappears',
    (tester) async {
      final repository = SubmitRepository();
      final vm = PointOfPurchaseViewModel(repository);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PointOfPurchaseDetailScreen(documentName: 'POP/1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(vm.isSubmitting, isTrue);
      expect(vm.selectedRecord?['docstatus'], 0);
      expect(await vm.submitPointOfPurchase('POP/1'), isFalse);
      expect(repository.calls, 1);
      repository.status = 1;
      repository.result.complete(document(1));
      await tester.pumpAndSettle();
      expect(vm.selectedRecord?['docstatus'], 1);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Purchase submitted successfully'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  for (final status in [1, 2]) {
    testWidgets('non-draft status $status has no Submit button', (
      tester,
    ) async {
      final vm = PointOfPurchaseViewModel(SubmitRepository(status: status));
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PointOfPurchaseDetailScreen(documentName: 'POP/1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsNothing);
      expect(await vm.submitPointOfPurchase('POP/1'), isFalse);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    });
  }
  test('submission failure leaves draft content visible and exposes the server error', () async {
    final repository = SubmitRepository();
    final vm = PointOfPurchaseViewModel(repository);
    await vm.loadPointOfPurchase('POP/1');
    final pending = vm.submitPointOfPurchase('POP/1');
    repository.result.completeError(
      const AppException('Insufficient permission', statusCode: 403),
    );
    expect(await pending, isFalse);
    expect(vm.selectedRecord?['docstatus'], 0);
    expect(vm.submitErrorMessage, 'Insufficient permission');
    expect(vm.isSubmitting, isFalse);
    vm.dispose();
  });
  test('a previous session cannot publish a completed submission', () async {
    final repository = SubmitRepository();
    final vm = PointOfPurchaseViewModel(repository);
    await vm.loadPointOfPurchase('POP/1');
    final pending = vm.submitPointOfPurchase('POP/1');
    vm.resetSession();
    repository.result.complete(document(1));
    expect(await pending, isFalse);
    expect(vm.selectedRecord, isNull);
    vm.dispose();
  });
  group('Frappe submission transport and cache', () {
    late ConnectivityService network;
    late CacheManager cache;
    late Dio dio;
    late PointOfPurchaseRepository repository;
    late List<RequestOptions> requests;
    var draftStatus = 0;
    var submitStatus = 1;
    var httpStatus = 200;
    const path = '/api/resource/Supplier%20Point%20Of%20Purchase/POP%2F1';
    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      network = ConnectivityService();
      final store = CacheService(const FlutterSecureStorage());
      await store.initialize();
      cache = CacheManager(store, network, 'https://erp.example');
      await cache.activate('alice');
      requests = [];
      draftStatus = 0;
      submitStatus = 1;
      httpStatus = 200;
      dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
      dio.httpClientAdapter = Adapter((request) {
        requests.add(request);
        if (request.method == 'GET') {
          return response({'message': document(draftStatus)});
        }
        if (httpStatus != 200) {
          return response({'message': 'Validation failed'}, httpStatus);
        }
        return response({'message': document(submitStatus)});
      });
      final api = ApiClient(
        DioClient(dio: dio),
        cache: cache,
        connectivity: network,
      );
      repository = PointOfPurchaseRepository(
        FrappeResourceApi(api),
        methods: FrappeMethodApi(api),
      );
      await cache.read(path, null, () async => {'data': document(0)});
    });
    tearDown(() {
      dio.close();
      network.dispose();
    });
    test('warehouse accounts use the selected collection location and all six fields', () async {
      final accounts = {
        for (final field in PointOfPurchaseRepository.warehouseAccountFields)
          field: 'Account for $field',
      };
      dio.httpClientAdapter = Adapter((request) {
        expect(request.path, '/api/method/frappe.client.get_list');
        expect(
          request.queryParameters['doctype'],
          'Warehouse wise Account Setting',
        );
        expect(jsonDecode(request.queryParameters['filters'] as String), {
          'collection_location': 'COCOA WH1 - CSTL',
        });
        expect(
          jsonDecode(request.queryParameters['fields'] as String),
          PointOfPurchaseRepository.warehouseAccountFields,
        );
        expect(request.queryParameters['limit_page_length'], 1);
        return response({
          'message': [accounts],
        });
      });
      expect(
        await repository.getWarehouseAccounts('COCOA WH1 - CSTL'),
        accounts,
      );
    });
    test(
      'warehouse without settings clears all six account defaults',
      () async {
        dio.httpClientAdapter = Adapter((_) => response({'message': []}));
        final accounts = await repository.getWarehouseAccounts('No settings');
        expect(accounts.keys, PointOfPurchaseRepository.warehouseAccountFields);
        expect(accounts.values, everyElement(isNull));
      },
    );
    test('fresh server document is submitted and confirmed response replaces draft cache', () async {
      final result = await repository.submitPointOfPurchase('POP/1');
      expect(result['docstatus'], 1);
      expect(requests.map((r) => r.path), [
        '/api/method/frappe.client.get',
        '/api/method/frappe.client.submit',
      ]);
      final payload =
          jsonDecode((requests.last.data as Map)['doc'] as String) as Map;
      expect(payload['doctype'], 'Supplier Point Of Purchase');
      expect(payload['name'], 'POP/1');
      expect(payload['supplier_pop_item'], isNotEmpty);
      expect(cache.store.entries.values.single.data, {'data': document(1)});
    });
    test(
      'offline submission performs no requests and preserves draft cache',
      () async {
        network.offline = true;
        await expectLater(
          repository.submitPointOfPurchase('POP/1'),
          throwsA(isA<AppException>()),
        );
        expect(requests, isEmpty);
        expect(cache.store.entries.values.single.data, {'data': document(0)});
      },
    );
    test('server-side non-draft status prevents the submit POST', () async {
      draftStatus = 1;
      await expectLater(
        repository.submitPointOfPurchase('POP/1'),
        throwsA(isA<AppException>()),
      );
      expect(requests, hasLength(1));
    });
    test(
      'server validation error never changes the saved draft to submitted',
      () async {
        httpStatus = 417;
        await expectLater(
          repository.submitPointOfPurchase('POP/1'),
          throwsA(isA<AppException>()),
        );
        expect(cache.store.entries.values.single.data, {'data': document(0)});
      },
    );
    test(
      'an unconfirmed success response is not accepted as submitted',
      () async {
        submitStatus = 0;
        await expectLater(
          repository.submitPointOfPurchase('POP/1'),
          throwsA(isA<AppException>()),
        );
        expect(cache.store.entries.values.single.data, {'data': document(0)});
      },
    );
  });
}
