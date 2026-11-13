import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_payment_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/payment_entry_list_viewmodel.dart';
import 'package:cml_si_buying/shared/widgets/app_paginated_list.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Future<List<Map<String, dynamic>>> Function(int) respond = (offset) async =>
      _rows(offset, offset == 0 ? 50 : 3);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final rows = await respond(options.queryParameters['limit_start'] as int);
    return ResponseBody.fromString(
      jsonEncode({'data': rows}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

List<Map<String, dynamic>> _rows(int start, int count) => List.generate(
  count,
  (index) => {'name': 'ROW-${start + index}', 'supplier_name': 'Supplier'},
);

void main() {
  for (final type in ['purchases', 'suppliers', 'payments']) {
    late Dio dio;
    late _Adapter adapter;
    late Future<void> Function() load, more;
    late int Function() count;
    late bool Function() hasMore;
    late String? Function() error;
    late VoidCallback dispose;

    setUp(() {
      adapter = _Adapter();
      dio = Dio(BaseOptions(baseUrl: 'https://erp.example'))
        ..httpClientAdapter = adapter;
      final api = FrappeResourceApi(ApiClient(DioClient(dio: dio)));
      if (type == 'purchases') {
        final vm = PointOfPurchaseViewModel(PointOfPurchaseRepository(api));
        load = vm.loadPointOfPurchases;
        more = vm.loadMore;
        count = () => vm.records.length;
        hasMore = () => vm.hasMore;
        error = () => vm.loadMoreError;
        dispose = vm.dispose;
      } else if (type == 'suppliers') {
        final vm = SupplierViewModel(SupplierRepository(api));
        load = vm.loadSuppliers;
        more = vm.loadMore;
        count = () => vm.suppliers.length;
        hasMore = () => vm.hasMore;
        error = () => vm.loadMoreError;
        dispose = vm.dispose;
      } else {
        final vm = PaymentEntryListViewModel(SupplierPaymentRepository(api));
        load = vm.load;
        more = () => vm.load(more: true);
        count = () => vm.records.length;
        hasMore = () => vm.hasMore;
        error = () => vm.error;
        dispose = vm.dispose;
      }
    });

    tearDown(() {
      dispose();
      dio.close();
    });

    test('$type requests 50, appends next page and stops at the end', () async {
      await load();
      expect(count(), 50);
      expect(hasMore(), isTrue);
      await more();
      expect(count(), 53);
      expect(hasMore(), isFalse);
      await more();
      expect(adapter.requests.map((r) => r.queryParameters['limit_start']), [
        0,
        50,
      ]);
      expect(
        adapter.requests.every(
          (r) => r.queryParameters['limit_page_length'] == 50,
        ),
        isTrue,
      );
    });

    test(
      '$type retries the same offset and prevents concurrent pages',
      () async {
        await load();
        adapter.respond = (_) async => throw StateError('offline');
        await more();
        expect(count(), 50);
        expect(error(), isNotNull);
        final pending = Completer<List<Map<String, dynamic>>>();
        adapter.respond = (_) => pending.future;
        final retry = more();
        await more();
        pending.complete([_rows(49, 1).single, ..._rows(50, 2)]);
        await retry;
        expect(count(), 52);
        expect(error(), isNull);
        expect(adapter.requests.map((r) => r.queryParameters['limit_start']), [
          0,
          50,
          50,
        ]);
      },
    );

    test('$type ignores a stale page after refreshing', () async {
      await load();
      final pending = Completer<List<Map<String, dynamic>>>();
      final started = Completer<void>();
      adapter.respond = (offset) {
        if (offset == 50) {
          started.complete();
          return pending.future;
        }
        return Future.value(_rows(100, 2));
      };
      final page = more();
      await started.future;
      await load();
      pending.complete(_rows(50, 3));
      await page;
      expect(count(), 2);
      expect(hasMore(), isFalse);
    });
  }

  testWidgets('scrolling loads another page automatically', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPaginatedList(
            hasMore: true,
            loading: false,
            onLoadMore: () async {
              calls++;
              await pending.future;
            },
            child: ListView.builder(
              controller: controller,
              itemExtent: 80,
              itemCount: 50,
              itemBuilder: (_, index) => Text('Record $index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    controller.jumpTo(controller.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    pending.complete();
  });

  testWidgets(
    'a short filtered list fills its viewport and errors wait for retry',
    (tester) async {
      var calls = 0;
      Future<void> show(String? error) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPaginatedList(
              hasMore: true,
              loading: false,
              error: error,
              onLoadMore: () async {
                calls++;
              },
              child: ListView(children: const [Text('Record')]),
            ),
          ),
        ),
      );
      await show(null);
      await tester.pumpAndSettle();
      expect(calls, 1);
      await show('Connection failed');
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.tap(find.text('Retry loading more'));
      await tester.pump();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
