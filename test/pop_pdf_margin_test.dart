import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:cml_si_buying/core/widgets/invoice_html_print_preview_screen.dart';

class _Raster extends PdfRaster {
  _Raster() : super(300, 600, Uint8List(0));
  @override
  Future<Uint8List> toPng() async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
  );
}

class _Printing extends PrintingPlatform {
  int rasterCalls = 0;
  Future<PrintingInfo>? pendingInfo;
  @override
  Future<PrintingInfo> info() async =>
      await (pendingInfo ?? Future.value(const PrintingInfo()));
  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {
    rasterCalls++;
    yield _Raster();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'PDF starts before native preview is ready and shares its request',
    (tester) async {
      final previous = PrintingPlatform.instance;
      final info = Completer<PrintingInfo>();
      PrintingPlatform.instance = _Printing()..pendingInfo = info.future;
      addTearDown(() => PrintingPlatform.instance = previous);
      final pdf = Completer<Uint8List>();
      var requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: InvoiceHtmlPrintPreviewScreen(
            htmlContent: '',
            title: 'Purchase invoice',
            loadPdf: () {
              requests++;
              return pdf.future;
            },
          ),
        ),
      );
      expect(requests, 1);
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      final first = preview.build(PdfPageFormat.a4);
      final second = preview.build(PdfPageFormat.a4);
      final source = Uint8List.fromList('%PDF-1.4 invoice'.codeUnits);
      pdf.complete(source);
      expect(await first, same(source));
      expect(await second, same(source));
      expect(requests, 1);
      await tester.pumpWidget(const SizedBox());
      info.complete(const PrintingInfo());
      await tester.pump();
    },
  );

  testWidgets(
    'server PDF with existing margins passes through without rasterization',
    (tester) async {
      final previous = PrintingPlatform.instance;
      final platform = _Printing();
      PrintingPlatform.instance = platform;
      addTearDown(() => PrintingPlatform.instance = previous);
      final source = Uint8List.fromList(
        '%PDF-1.4 original server template'.codeUnits,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: InvoiceHtmlPrintPreviewScreen(
            htmlContent: '',
            title: 'POP TEMPLATE',
            documentId: 'CAMLSCC-1049',
            loadPdf: () async => source,
          ),
        ),
      );
      await tester.pump();
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      final output = await preview.build(PdfPageFormat.a4);
      expect(output, same(source));
      expect(platform.rasterCalls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'POP PDF gains physical margins and regenerates when margin changes',
    (tester) async {
      final previous = PrintingPlatform.instance;
      PrintingPlatform.instance = _Printing();
      addTearDown(() => PrintingPlatform.instance = previous);
      var requests = 0;
      Future<Uint8List> load() async {
        requests++;
        return Uint8List.fromList([1, 2, 3]);
      }

      Future<Uint8List> build(double margin) async {
        await tester.pumpWidget(
          MaterialApp(
            home: InvoiceHtmlPrintPreviewScreen(
              htmlContent: '',
              title: 'POP TEMPLATE',
              documentId: 'SUP-1',
              loadPdf: load,
              pdfMarginMm: margin,
            ),
          ),
        );
        await tester.pump();
        final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
        return (await tester.runAsync(
          () async => await preview.build(PdfPageFormat.a4),
        ))!;
      }

      final first = await build(8);
      List<double> size(Uint8List bytes) {
        final match = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
            .firstMatch(latin1.decode(bytes));
        expect(match, isNotNull);
        return [double.parse(match!.group(1)!), double.parse(match.group(2)!)];
      }

      final firstSize = size(first);
      expect(firstSize[0], closeTo(72 + 16 * PdfPageFormat.mm, 0.01));
      expect(firstSize[1], closeTo(144 + 16 * PdfPageFormat.mm, 0.01));
      final second = await build(12);
      expect(size(second)[0], closeTo(72 + 24 * PdfPageFormat.mm, 0.01));
      expect(requests, 2);
      // Exercise the same lifecycle callback Flutter invokes on hot reload.
      // ignore: invalid_use_of_protected_member
      tester.state(find.byType(InvoiceHtmlPrintPreviewScreen)).reassemble();
      await tester.pump();
      await tester.runAsync(
        () async => await tester
            .widget<PdfPreview>(find.byType(PdfPreview))
            .build(PdfPageFormat.a4),
      );
      expect(requests, 3);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
