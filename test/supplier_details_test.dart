import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/shared/widgets/app_text_field.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/supplier/models/supplier_model.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/supplier_details_screen.dart';
import 'package:cml_si_buying/features/supplier/views/create_supplier_screen.dart';

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
  Future<List<String>> getSupplierFieldOptions(String doctype) async => [
    '$doctype option',
  ];
  @override
  Future<String> getSupplierCardHtml(String supplierId) async =>
      throw const AppException('Card format unavailable');
  @override
  Future<Uint8List> getSupplierCard(String supplierId) async =>
      throw const AppException('Card format unavailable');
  @override
  Future<List<SupplierModel>> getSuppliers({int offset = 0}) async => const [
    SupplierModel(id: 'SUP/A 1', name: 'North Supplier'),
  ];
  @override
  Future<Map<String, dynamic>> getSupplier(String name) {
    detailCalls++;
    return (requests[name] ??= Completer()).future;
  }
}

class CardAdapter implements HttpClientAdapter {
  CardAdapter(this.respond);
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

class ImageSupplierRepository extends Suppliers {
  String? updatedId;
  @override
  Future<SupplierModel> updateSupplier(
    String id,
    Map<String, dynamic> fields,
  ) async {
    updatedId = id;
    saved = fields;
    return SupplierModel(id: id, name: fields['supplier_name'] as String);
  }

  bool failUpload = false;
  int uploads = 0;
  Map<String, dynamic>? saved;
  @override
  Future<String> uploadSupplierImage(Uint8List bytes, String filename) async {
    uploads++;
    expect(bytes, [1, 2, 3]);
    expect(filename, 'supplier.png');
    if (failUpload) throw const AppException('Image upload failed');
    return '/files/supplier.png';
  }

  @override
  Future<SupplierModel> createSupplier(Map<String, dynamic> fields) async {
    saved = fields;
    return const SupplierModel(id: 'SUP-1', name: 'Supplier');
  }
}

class CaptureSupplierViewModel extends SupplierViewModel {
  CaptureSupplierViewModel() : super(Suppliers());
  Map<String, dynamic>? payload;
  @override
  Future<bool> createSupplier(
    Map<String, dynamic> fields, {
    Uint8List? imageBytes,
    String? imageFilename,
    String? supplierId,
  }) async {
    payload = fields;
    return false;
  }
}

void main() {
  test(
    'editing uploads replacement image and updates the existing supplier',
    () async {
      final repository = ImageSupplierRepository();
      final vm = SupplierViewModel(repository);
      addTearDown(vm.dispose);
      expect(
        await vm.createSupplier(
          {'supplier_name': 'Updated supplier'},
          supplierId: 'SUP-1',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          imageFilename: 'supplier.png',
        ),
        isTrue,
      );
      expect(repository.updatedId, 'SUP-1');
      expect(repository.saved!['image'], '/files/supplier.png');
      expect(vm.suppliers.single.name, 'Updated supplier');
    },
  );
  testWidgets('primary address is validated and sent without contact number', (
    tester,
  ) async {
    final vm = CaptureSupplierViewModel();
    await tester.pumpWidget(
      ChangeNotifierProvider<SupplierViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreateSupplierScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = tester.widgetList<AppTextField>(find.byType(AppTextField));
    AppTextField field(String label) =>
        fields.singleWhere((item) => item.label == label);
    expect(fields.any((item) => item.label == 'Contact number'), isFalse);
    expect(field('Country').controller!.text, 'Solomon Islands');
    expect(field('Country').required, isTrue);
    field('Supplier name').controller!.text = 'New Supplier';
    tester
        .widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>))
        .first
        .onChanged!('Supplier Group option');
    field('Address Line 2').controller!.text = 'Unit 2';
    expect(field('Address Line 1').validator!(''), isNotNull);
    expect(field('City').validator!(''), isNotNull);
    field('Address Line 1').controller!.text = 'Main Road';
    field('City').controller!.text = 'Honiara';
    field('State').controller!.text = 'Capital Territory';
    field('ZIP Code').controller!.text = '12345';
    await tester.tap(find.text('Save supplier'));
    await tester.pumpAndSettle();
    expect(vm.payload, containsPair('address_line1', 'Main Road'));
    expect(vm.payload, containsPair('address_line2', 'Unit 2'));
    expect(vm.payload, containsPair('city', 'Honiara'));
    expect(vm.payload, containsPair('state', 'Capital Territory'));
    expect(vm.payload, containsPair('pincode', '12345'));
    expect(vm.payload, containsPair('country', 'Solomon Islands'));
    expect(vm.payload!.containsKey('custom_contact_number'), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  test(
    'supplier dropdown lists request the correct doctypes and all pages',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
      dio.httpClientAdapter = CardAdapter((options) {
        requests.add(options);
        final offset = options.queryParameters['limit_start'] as int;
        final rows = offset == 0
            ? List.generate(200, (i) => {'name': 'Record $i'})
            : [
                {'name': 'Last record'},
              ];
        return ResponseBody.fromString(
          jsonEncode({'data': rows}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      final repository = SupplierRepository(
        FrappeResourceApi(ApiClient(DioClient(dio: dio))),
      );
      for (final doctype in [
        'Village',
        'Island',
        'Supplier Group',
        'Province',
      ]) {
        final options = await repository.getSupplierFieldOptions(doctype);
        expect(options.length, 201);
        expect(options, contains('Last record'));
        expect(
          Uri.decodeComponent(requests.last.path),
          '/api/resource/$doctype',
        );
        expect(requests.last.queryParameters['limit_start'], 200);
        expect(requests.last.queryParameters['fields'], '["name"]');
      }
      dio.close();
    },
  );

  testWidgets('supplier form uses fetched dropdowns and all supplier types', (
    tester,
  ) async {
    final vm = SupplierViewModel(Suppliers());
    await tester.pumpWidget(
      ChangeNotifierProvider<SupplierViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreateSupplierScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile picture'), findsOneWidget);
    final dropdowns = tester
        .widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>))
        .toList();
    expect(dropdowns.length, 5);
    final values = dropdowns
        .map((field) => field.items!.map((item) => item.value).toList())
        .toList();
    expect(values, contains(equals(['Supplier Group option'])));
    expect(values, contains(equals(['Village option'])));
    expect(values, contains(equals(['Island option'])));
    expect(values, contains(equals(['Province option'])));
    expect(values[1], [
      'Company',
      'Individual',
      'Partnership',
      'Walk-in',
      'Agent',
      'Trading',
      'Vesel',
    ]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

  testWidgets(
    'supplier gallery opens native picker and cancellation keeps the form',
    (tester) async {
      final vm = SupplierViewModel(Suppliers());
      addTearDown(vm.dispose);
      var opened = false;
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        opened = true;
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<SupplierViewModel>.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CreateSupplierScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Choose file'), findsOneWidget);
      expect(find.textContaining('Unable to'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('supplier card uses printview HTML for the selected supplier without letterhead', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://192.168.101.127'));
    addTearDown(dio.close);
    dio.httpClientAdapter = CardAdapter((request) {
      expect(request.path, '/printview');
      expect(request.queryParameters, {
        'doctype': 'Supplier',
        'name': 'CAMLSCP-1967',
        'format': 'Card front 2',
        'no_letterhead': 1,
      });
      expect(request.responseType, ResponseType.plain);
      return ResponseBody.fromString(
        '<html><body><div class="print-format">Supplier card</div></body></html>',
        200,
      );
    });
    final repository = SupplierRepository(
      FrappeResourceApi(ApiClient(DioClient(dio: dio))),
    );
    expect(
      await repository.getSupplierCardHtml('CAMLSCP-1967'),
      contains('Supplier card'),
    );
    dio.httpClientAdapter = CardAdapter(
      (_) => ResponseBody.fromString('<html>Login required</html>', 200),
    );
    await expectLater(
      repository.getSupplierCardHtml('CAMLSCP-1967'),
      throwsA(isA<AppException>()),
    );
  });
  test('PDF validation errors show the real ERP message instead of HTTP 417 fallback', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
    addTearDown(dio.close);
    dio.httpClientAdapter = CardAdapter(
      (_) => ResponseBody.fromString(
        jsonEncode({
          'exc_type': 'ValidationError',
          '_server_messages': jsonEncode([
            jsonEncode({'message': 'Print Format Card front 2 is disabled'}),
          ]),
        }),
        417,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    final repository = SupplierRepository(
      FrappeResourceApi(ApiClient(DioClient(dio: dio))),
    );
    await expectLater(
      repository.getSupplierCard('SUP/A 1'),
      throwsA(
        isA<AppException>()
            .having(
              (e) => e.message,
              'message',
              'Print Format Card front 2 is disabled',
            )
            .having((e) => e.code, 'code', 'ValidationError')
            .having((e) => e.statusCode, 'status', 417),
      ),
    );
  });
  test(
    'PDF rendering exception without server messages retains its cause',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
      addTearDown(dio.close);
      dio.httpClientAdapter = CardAdapter(
        (_) => ResponseBody.fromString(
          jsonEncode({
            'exc_type': 'PDFGenerationError',
            'exception': 'PDFGenerationError: PDF engine is unavailable',
          }),
          417,
        ),
      );
      final api = ApiClient(DioClient(dio: dio));
      await expectLater(
        api.getPdf(
          '/api/method/frappe.utils.print_format.download_pdf',
          queryParameters: {},
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'PDFGenerationError: PDF engine is unavailable',
          ),
        ),
      );
    },
  );
  test('image upload sends multipart file and reads ERP file URL', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://erp.example',
        contentType: Headers.jsonContentType,
      ),
    );
    addTearDown(dio.close);
    dio.httpClientAdapter = CardAdapter((request) {
      expect(request.path, '/api/method/upload_file');
      expect(request.method, 'POST');
      expect(request.contentType, startsWith('multipart/form-data'));
      final form = request.data as FormData;
      expect(
        form.fields,
        contains(
          isA<MapEntry<String, String>>()
              .having((entry) => entry.key, 'key', 'is_private')
              .having((entry) => entry.value, 'value', '0'),
        ),
      );
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'supplier.png');
      return ResponseBody.fromString(
        '{"message":{"file_url":"/files/supplier.png"}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final api = ApiClient(DioClient(dio: dio));
    expect(
      await api.uploadImage(Uint8List.fromList([1, 2, 3]), 'supplier.png'),
      '/files/supplier.png',
    );
  });
  test('supplier save uploads selected image and includes its URL', () async {
    final repository = ImageSupplierRepository();
    final vm = SupplierViewModel(repository);
    addTearDown(vm.dispose);
    expect(
      await vm.createSupplier(
        {'supplier_name': 'Supplier'},
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageFilename: 'supplier.png',
      ),
      isTrue,
    );
    expect(repository.saved?['image'], '/files/supplier.png');
    expect(repository.uploads, 1);
  });
  test(
    'failed image upload does not create supplier and keeps retry available',
    () async {
      final repository = ImageSupplierRepository()..failUpload = true;
      final vm = SupplierViewModel(repository);
      addTearDown(vm.dispose);
      expect(
        await vm.createSupplier(
          {'supplier_name': 'Supplier'},
          imageBytes: Uint8List.fromList([1, 2, 3]),
          imageFilename: 'supplier.png',
        ),
        isFalse,
      );
      expect(repository.saved, isNull);
      expect(vm.errorMessage, 'Image upload failed');
      expect(vm.isSaving, isFalse);
      repository.failUpload = false;
      expect(await vm.createSupplier({'supplier_name': 'Supplier'}), isTrue);
      expect(repository.saved!.containsKey('image'), isFalse);
      expect(repository.uploads, 1);
    },
  );
  test(
    'supplier card requests the exact ERP print format with supplier ID',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
      addTearDown(dio.close);
      dio.httpClientAdapter = CardAdapter((request) {
        expect(
          request.path,
          '/api/method/frappe.utils.print_format.download_pdf',
        );
        expect(request.queryParameters, {
          'doctype': 'Supplier',
          'name': 'SUP/A 1',
          'format': 'Card front 2',
          'no_letterhead': 1,
        });
        expect(request.responseType, ResponseType.bytes);
        return ResponseBody.fromString('%PDF-1.4 sample', 200);
      });
      final repository = SupplierRepository(
        FrappeResourceApi(ApiClient(DioClient(dio: dio))),
      );
      expect(
        String.fromCharCodes(await repository.getSupplierCard('SUP/A 1')),
        startsWith('%PDF-'),
      );
      dio.httpClientAdapter = CardAdapter(
        (_) => ResponseBody.fromString('<html>Sign in</html>', 200),
      );
      await expectLater(
        repository.getSupplierCard('SUP/A 1'),
        throwsA(isA<AppException>()),
      );
    },
  );
  testWidgets('supplier details remain visible when the card fails', (
    tester,
  ) async {
    final repository = Suppliers();
    final vm = SupplierViewModel(repository);
    await tester.pumpWidget(
      ChangeNotifierProvider<SupplierViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupplierDetailsScreen(supplierId: 'SUP/A 1'),
        ),
      ),
    );
    repository.requests['SUP/A 1']!.complete({
      'name': 'SUP/A 1',
      'supplier_name': 'North Supplier',
      'email_id': 'north@example.com',
      'tax_id': 'TAX-123',
      'custom_registration': 'REG-123',
      'api_key': 'must-stay-hidden',
      'accounts': [
        {'company': 'CAML', 'account': 'Payables - CAML'},
      ],
    });
    await tester.pumpAndSettle();
    expect(find.text('Supplier details'), findsOneWidget);
    expect(find.text('Supplier information'), findsOneWidget);
    expect(find.text('north@example.com'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('TAX-123'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('TAX-123'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('REG-123'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Additional details'), findsOneWidget);
    expect(find.text('REG-123'), findsOneWidget);
    expect(find.text('Accounts (1)'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Payables - CAML'), findsOneWidget);
    expect(find.text('must-stay-hidden'), findsNothing);
    expect(find.text('Print Preview'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });

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
