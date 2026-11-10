import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/models/html_print_document.dart';
import 'package:cml_si_buying/core/widgets/html_print_preview_screen.dart';
import 'package:cml_si_buying/core/widgets/invoice_html_print_preview_screen.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/supplier_details_screen.dart';

const html =
    '<html><head><style>td{border:1px solid black}</style></head>'
    '<body><table><tr><td>Supplier</td></tr></table><img src="/files/logo.png"></body></html>';

class PrintRepository extends SupplierRepository {
  PrintRepository()
    : super(
        FrappeResourceApi(
          ApiClient(
            DioClient(dio: Dio(BaseOptions(baseUrl: 'https://erp.example'))),
          ),
        ),
      );
  int printCalls = 0;
  Completer<String> result = Completer<String>();
  @override
  Future<Map<String, dynamic>> getSupplier(String name) async => {
    'name': name,
    'supplier_name': 'Supplier',
  };
  @override
  Future<String> getSupplierCardHtml(String supplierId) {
    printCalls++;
    return result.future;
  }

  @override
  Future<Map<String, String>> printCookies() async => {'sid': 'test-session'};
}

void main() {
  test(
    'page preview fits desktop invoice layout with zoom and hides ERP controls',
    () {
      final result = InvoiceHtmlPrintPreviewScreen.prepareHtml(
        '<html><head><meta name="viewport" content="width=device-width, maximum-scale=1">'
        '<style>.invoice{width:800px}</style></head>'
        '<body><div class="print-toolbar">Print Get PDF</div>'
        '<div class="print-format"><div class="invoice">Invoice</div></div></body></html>',
      );
      expect(RegExp('name="viewport"').allMatches(result).length, 1);
      expect(result, contains('width=980, user-scalable=yes'));
      expect(result, isNot(contains('maximum-scale=1')));
      expect(
        result,
        contains(
          '.print-toolbar,.action-banner,.page-head,.printview-header{display:none!important;}',
        ),
      );
      expect(result, contains('.invoice{width:800px}'));
      expect(result, contains('<div class="invoice">Invoice</div>'));
    },
  );
  test('extracts raw HTML and both Frappe wrappers while preserving styles and relative assets', () {
    for (final response in [
      html,
      {'message': html},
      {
        'message': {'html': html},
      },
      jsonEncode({'message': html}),
    ]) {
      final result = HtmlPrintDocument.extractHtml(response);
      expect(result, contains('<style>td{border:1px solid black}</style>'));
      expect(result, contains('src="/files/logo.png"'));
      expect(result, contains('name="viewport"'));
      expect(result, isNot(contains('&lt;')));
    }
  });
  test('wraps fragments, preserves existing viewport, and rejects empty or invalid responses', () {
    expect(
      HtmlPrintDocument.extractHtml('<table><tr><td>Value</td></tr></table>'),
      startsWith('<!DOCTYPE html>'),
    );
    const document =
        '<html><head><meta name="viewport" content="width=532"></head><body>Card</body></html>';
    expect(HtmlPrintDocument.extractHtml(document), document);
    for (final response in [
      null,
      '',
      'Not HTML',
      {'message': []},
      '<html>Login required</html>',
    ]) {
      expect(
        () => HtmlPrintDocument.extractHtml(response),
        throwsA(isA<AppException>()),
      );
    }
  });
  test(
    'viewmodel deduplicates requests and rejects previous-session results',
    () async {
      final repository = PrintRepository();
      final vm = SupplierViewModel(repository);
      addTearDown(vm.dispose);
      final pending = vm.loadPrintPreview('SUP-1');
      expect(await vm.loadPrintPreview('SUP-1'), isNull);
      expect(repository.printCalls, 1);
      vm.resetSession();
      repository.result.complete(html);
      expect(await pending, isNull);
      expect(vm.isLoadingPrint, isFalse);
    },
  );
  test('viewmodel exposes retryable API errors', () async {
    final repository = PrintRepository();
    final vm = SupplierViewModel(repository);
    addTearDown(vm.dispose);
    final pending = vm.loadPrintPreview('SUP-1');
    repository.result.completeError(
      const AppException('Print permission required'),
    );
    expect(await pending, isNull);
    expect(vm.printError, 'Print permission required');
    repository.result = Completer<String>()..complete(html);
    final document = await vm.loadPrintPreview('SUP-1');
    expect(document!.baseUrl.toString(), 'https://erp.example/printview');
    expect(document.documentId, 'SUP-1');
    expect(document.cookies['sid'], 'test-session');
    expect(vm.printError, isNull);
  });
  testWidgets('supplier screen loads a fitted card above supplier details', (
    tester,
  ) async {
    final repository = PrintRepository();
    final vm = SupplierViewModel(repository);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupplierDetailsScreen(supplierId: 'SUP-1'),
        ),
      ),
    );
    await tester.pump();
    expect(repository.printCalls, 1);
    repository.result.complete(html);
    await tester.pumpAndSettle();
    final preview = tester.widget<HtmlPrintPreviewScreen>(
      find.byType(HtmlPrintPreviewScreen),
    );
    expect(preview.cardOnly, isTrue);
    expect(preview.embedded, isTrue);
    expect(preview.htmlContent, contains('<table>'));
    expect(find.text('Print Preview'), findsNothing);
    expect(find.text('Supplier information'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
