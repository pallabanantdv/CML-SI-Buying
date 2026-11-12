import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/purchase_detail_model.dart';
import 'package:cml_si_buying/features/point_of_purchase/printing/pop_receipt_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('outstanding uses the saved balance or net payable less payments', () {
    PurchaseDetailModel purchase(Map<String, dynamic> fields) =>
        PurchaseDetailModel.fromJson(fields);
    expect(purchase({'net_payable': 335}).outstandingBalance, 335);
    expect(
      purchase({
        'net_payable': 335,
        'advances': 100,
        'pop_cash_payment': [
          {'paid_amount': 100},
          {'paid_amount': 50},
        ],
      }).outstandingBalance,
      185,
    );
    for (final paid in [335, 400]) {
      expect(
        purchase({
          'net_payable': 335,
          'pop_cash_payment': [
            {'paid_amount': paid},
          ],
        }).outstandingBalance,
        0,
      );
    }
    expect(
      purchase({'outstanding_amount': '25.50', 'net_payable': 335})
          .outstandingBalance,
      25.5,
    );
    expect(
      purchase({'outstanding_amount': 0, 'net_payable': 335})
          .outstandingBalance,
      0,
    );
    expect(purchase({}).outstandingBalance, isNull);
  });
  test(
    'local template keeps 58 mm paper width for full and long receipts',
    () async {
      for (final bags in [1, 40]) {
        final purchase = PurchaseDetailModel.fromJson({
          'name': 'CPV-26-06414',
          'company': 'CAML',
          'date': '2026-11-10',
          'supplier_name': 'CAMLSCP-1970',
          'supplier_name1': 'Test Supplier',
          'no_of_bag': bags,
          'gross_weight': 50,
          'custom_product_type': 'Copra',
          'rate': 10,
          'freight': 5,
          'sea_fare': 5,
          'ship_payment': 15,
          'others': 5,
          'advances': 100,
          'village': 'Ado',
          'vesel': 'CAMLSCP-264',
          'island': 'Gela',
          'province': 'Choiseul Province',
          'phonemobile_no': '446456846',
          'delivery_type': 'Courier',
          'courier_name': 'Courier',
          'total_bag': List.generate(
            bags,
            (i) => {'bag_number': 'Bag ${i + 1}', 'weight': 50},
          ),
          'supplier_pop_item': [
            {
              'item_code': 'RAW COPRA',
              'qty': 0.045,
              'uom': 'MT',
              'rate': 10,
              'total_amount': 450,
            },
          ],
          'total_amount': 450,
          'total_deduction': 115,
          'net_payable': 335,
          'advance': [
            {
              'reference_name': 'JV-001',
              'reference_type': 'Journal Entry',
              'remarks': 'Supplier advance',
              'advance_amount': 100,
              'allocated_amount': 60,
            },
            {
              'reference_name': 'JV-002',
              'advance_amount': 80,
              'allocated_amount': 40,
            },
          ],
          'instant_paid': 1,
          'pop_cash_payment': [
            {
              'payment_type': 'Bank',
              'payment_from': 'CAML Bank',
              'paid_amount': 335,
              'reference_no': 'PAY-001',
              'reference_date': '2026-11-10',
            },
          ],
        });
        final bytes = await PopReceiptPdf.build(purchase);
        final pdf = latin1.decode(bytes);
        expect(pdf.startsWith('%PDF-'), isTrue);
        expect(pdf, matches(RegExp(r'/BaseFont\s*/Helvetica\b')));
        expect(pdf, matches(RegExp(r'/BaseFont\s*/Helvetica-Bold\b')));
        expect(pdf, isNot(contains('Poppins')));
        expect(pdf, isNot(contains('AlikeAngular')));
        final box = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
            .firstMatch(pdf)!;
        expect(
          double.parse(box.group(1)!),
          closeTo(58 * PdfPageFormat.mm, .01),
        );
        expect(double.parse(box.group(2)!), greaterThan(100));
        expect(RegExp(r'/Type\s*/Page\b').allMatches(pdf).length, 1);
        if (bags == 1) {
          final file = File('build/pop-local-preview.pdf');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        }
      }
    },
  );
  test('empty fields take no paper while payment details and zero values remain visible', () async {
    double height(List<int> bytes) {
      final box = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
          .firstMatch(latin1.decode(bytes))!;
      return double.parse(box.group(2)!);
    }

    Future<List<int>> receipt(Map<String, dynamic> fields) =>
        PopReceiptPdf.build(
          PurchaseDetailModel.fromJson({'name': 'POP-1', ...fields}),
        );
    final empty = await receipt({});
    final blank = await receipt({
      'village': '   ',
      'province': '-',
      'courier_name': '',
      'moisture': null,
      'total_bag': [{}],
      'supplier_pop_item': [{}],
      'pop_cash_payment': [{}],
      'advance': [{}],
    });
    expect(height(blank), height(empty));
    final zero = await receipt({'freight': 0, 'net_payable': 0});
    expect(height(zero), greaterThan(height(empty)));
    final advanceWithZero = await receipt({
      'advance': [
        {'advance_amount': 0, 'allocated_amount': 0},
      ],
    });
    expect(height(advanceWithZero), greaterThan(height(empty)));
    final paid = await receipt({
      'pop_cash_payment': [
        {'payment_type': 'Cash', 'paid_amount': 20},
        {
          'payment_type': 'Bank',
          'paid_amount': 15,
          'reference_no': 'PAY-2',
          'reference_date': '2026-11-10',
        },
      ],
    });
    expect(height(paid), greaterThan(height(empty)));
    await File('build/pop-empty-preview.pdf').writeAsBytes(empty);
    await File('build/pop-payment-preview.pdf').writeAsBytes(paid);
  });
}
