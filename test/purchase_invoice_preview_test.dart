import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';

import 'purchase_submission_test.dart' as fixtures;

class InvoiceRepository extends PointOfPurchaseRepository {
  InvoiceRepository(super.resources);
  int status = 1;
  String? invoice = 'PINV/1';
  @override
  Future<Map<String, dynamic>> getPointOfPurchase(String name) async => {
    'name': name,
    'docstatus': status,
    'purchase_invoice': invoice,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late InvoiceRepository repository;
  late PointOfPurchaseViewModel vm;
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
    dio.httpClientAdapter = fixtures.Adapter((request) {
      requests.add(request);
      return ResponseBody.fromString(
        request.path == '/printview'
            ? '<html><body>Purchase invoice</body></html>'
            : '%PDF-1.4 invoice',
        200,
        headers: {
          Headers.contentTypeHeader: [
            request.path == '/printview' ? 'text/html' : 'application/pdf',
          ],
        },
      );
    });
    repository = InvoiceRepository(
      FrappeResourceApi(ApiClient(DioClient(dio: dio))),
    );
    vm = PointOfPurchaseViewModel(repository);
  });
  tearDown(() => vm.dispose());

  test('opens immediately without HTML requests and fetches only the PI PDF in English', () async {
    await vm.loadPointOfPurchase('POP/1');
    final document = await vm.loadInvoicePreview('POP/1');
    expect(document.documentId, 'PINV/1');
    expect(requests, isEmpty);
    await document.loadPdf!();
    expect(requests.length, 1);
    expect(
      requests.last.path,
      '/api/method/frappe.utils.print_format.download_pdf',
    );
    for (final request in requests) {
      expect(request.queryParameters, {
        'doctype': 'Purchase Invoice',
        'name': 'PINV/1',
        'format': 'PI',
        '_lang': 'en',
        'no_letterhead': 1,
      });
    }
  });

  test(
    'draft, cancelled and unlinked purchases cannot fetch invoice previews',
    () async {
      for (final status in [0, 2]) {
        repository.status = status;
        await vm.loadPointOfPurchase('POP/1');
        await expectLater(
          vm.loadInvoicePreview('POP/1'),
          throwsA(isA<AppException>()),
        );
      }
      repository.status = 1;
      repository.invoice = null;
      await vm.loadPointOfPurchase('POP/1');
      await expectLater(
        vm.loadInvoicePreview('POP/1'),
        throwsA(isA<AppException>()),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'POP uses the purchase document and POP TEMPLATE without a linked invoice',
    () async {
      repository.invoice = null;
      await vm.loadPointOfPurchase('POP/1');
      final document = await vm.loadPopPreview('POP/1');
      expect(document.title, 'POP TEMPLATE');
      expect(document.documentId, 'POP/1');
      expect(requests, isEmpty);
      await document.loadPdf!();
      expect(requests.single.queryParameters, {
        'doctype': 'Supplier Point Of Purchase',
        'name': 'POP/1',
        'format': 'POP TEMPLATE',
        '_lang': 'en',
        'no_letterhead': 1,
      });
    },
  );

  test(
    'POP rejects drafts, cancelled purchases and a different selected purchase',
    () async {
      for (final status in [0, 2]) {
        repository.status = status;
        await vm.loadPointOfPurchase('POP/1');
        await expectLater(
          vm.loadPopPreview('POP/1'),
          throwsA(isA<AppException>()),
        );
      }
      repository.status = 1;
      await vm.loadPointOfPurchase('POP/1');
      await expectLater(
        vm.loadPopPreview('POP/2'),
        throwsA(isA<AppException>()),
      );
      final document = await vm.loadPopPreview('POP/1');
      vm.resetSession();
      expect(() => document.loadPdf!(), throwsA(isA<AppException>()));
      expect(requests, isEmpty);
    },
  );

  test('PDF callback cannot fetch after the account changes', () async {
    await vm.loadPointOfPurchase('POP/1');
    final document = await vm.loadInvoicePreview('POP/1');
    vm.resetSession();
    expect(() => document.loadPdf!(), throwsA(isA<AppException>()));
    expect(requests, isEmpty);
  });
}
