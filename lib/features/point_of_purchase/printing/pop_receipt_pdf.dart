import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/purchase_detail_model.dart';

/// Local POP template, sized for a 58 mm thermal roll with 3 mm margins.
class PopReceiptPdf {
  static const paperWidth = 58 * PdfPageFormat.mm;
  static const pageMargin = 3 * PdfPageFormat.mm;

  static Future<Uint8List> build(PurchaseDetailModel purchase) async {
    // Use standard receipt fonts independently of the application's theme.
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/images/CAML Logo.png')).buffer
          .asUint8List(),
    );
    final pdf = pw.Document();
    bool hasValue(Object? value) =>
        value != null &&
        value.toString().trim().isNotEmpty &&
        value.toString().trim() != '-';
    String text(Object? value) =>
        hasValue(value) ? value.toString().trim() : '';
    String firstText(List<Object?> values) => values
        .map(text)
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    String number(double? value, [int digits = 2]) =>
        value == null ? '' : value.toStringAsFixed(digits);
    String money(double? value) => value == null ? '' : '\$ ${number(value)}';
    pw.Widget label(String title, Object? value) => !hasValue(value)
        ? pw.SizedBox()
        : pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1),
            child: pw.Text('$title: ${text(value)}'),
          );
    pw.Widget heading(String title) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
    pw.Widget total(String title, double? amount, {bool emphasized = false}) =>
        amount == null
        ? pw.SizedBox()
        : pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontWeight: emphasized
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                ),
                pw.Text(
                  money(amount),
                  style: pw.TextStyle(
                    fontSize: emphasized ? 9.5 : 7.5,
                    fontWeight: emphasized
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
    pw.Widget table(
      List<String> headers,
      List<List<String>> rows,
      Map<int, pw.TableColumnWidth> widths,
    ) {
      final visibleRows = rows.where((row) => row.any(hasValue)).toList();
      if (visibleRows.isEmpty) return pw.SizedBox();
      // Do not print a column whose values are all absent. Numeric zero stays.
      final columns = [
        for (var i = 0; i < headers.length; i++)
          if (visibleRows.any((row) => hasValue(row[i]))) i,
      ];
      return pw.TableHelper.fromTextArray(
        headers: [for (final index in columns) headers[index]],
        data: [
          for (final row in visibleRows)
            [for (final index in columns) row[index]],
        ],
        columnWidths: {
          for (var i = 0; i < columns.length; i++) i: widths[columns[i]]!,
        },
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColors.grey400, width: .4),
          bottom: pw.BorderSide(color: PdfColors.grey400, width: .4),
        ),
        headerStyle: pw.TextStyle(font: bold, fontSize: 7),
        cellStyle: pw.TextStyle(font: regular, fontSize: 7.5),
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 1, horizontal: 1),
        headerAlignment: pw.Alignment.centerLeft,
        cellAlignment: pw.Alignment.centerLeft,
        cellAlignments: {columns.length - 1: pw.Alignment.centerRight},
      );
    }

    final bags = (purchase.totalBag ?? <PurchaseBagDetail>[])
        .where((bag) => hasValue(bag.bagNumber) || bag.weight != null)
        .toList();
    final items = (purchase.supplierPopItem ?? <PurchaseItemDetail>[])
        .where(
          (item) =>
              hasValue(item.itemName) ||
              hasValue(item.itemCode) ||
              item.qty != null ||
              hasValue(item.uom) ||
              item.totalAmount != null,
        )
        .toList();
    final advances = (purchase.advance ?? <PurchaseAdvanceDetail>[])
        .where(
          (advance) =>
              hasValue(advance.referenceName) ||
              hasValue(advance.referenceType) ||
              hasValue(advance.remarks) ||
              advance.advanceAmount != null ||
              advance.allocatedAmount != null,
        )
        .toList();
    final payments = (purchase.popCashPayment ?? <PurchaseCashPaymentDetail>[])
        .where(
          (payment) =>
              hasValue(payment.paymentType) ||
              hasValue(payment.paymentFrom) ||
              payment.paidAmount != null ||
              hasValue(payment.referenceNo) ||
              hasValue(payment.referenceDate),
        )
        .toList();
    final children = <pw.Widget>[
      pw.Center(
        child: pw.Image(logo, width: 55, height: 26, fit: pw.BoxFit.contain),
      ),
      if (hasValue(purchase.company))
        pw.Center(
          child: pw.Text(
            purchase.company!,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      pw.SizedBox(height: 3),
      pw.Text(
        'P.O. Box 787 Unit 1, Lot 487, Parcell 192-004-217 Henderson Area, Honiara, Solomon Island',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 7),
      ),
      pw.Center(
        child: pw.Text(
          'Office Mobile No. (+677) 7426390',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ),
      pw.SizedBox(height: 3),
      label('Receipt No', purchase.name),
      label('Date', firstText([purchase.popDatetime, purchase.date])),
      pw.Center(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 2),
          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Text(
            'PURCHASE RECEIPT',
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
      label(
        'Received from',
        firstText([purchase.supplierName1, purchase.supplierName]),
      ),
      if (hasValue(purchase.supplierName1) &&
          purchase.supplierName1 != purchase.supplierName)
        label('Supplier ID', purchase.supplierName),
      // Keep the paired detail columns from the supplied template.
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                label('No. of bags', number(purchase.noOfBag, 0)),
                label('Moisture', purchase.moisture),
                label('FFA', purchase.ffa),
                label('Freight (\$)', number(purchase.freight)),
                label('Sea fare (\$)', number(purchase.seaFare)),
                label('Ship payment (\$)', number(purchase.shipPayment)),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                label('Total tare (MT)', number(purchase.tare15kgsbag, 3)),
                label('GW (kg)', number(purchase.grossWeight, 3)),
                label('Product type', purchase.customProductType),
                label('Rate/kg', money(purchase.rate)),
                label('Others (\$)', number(purchase.others)),
                label('Advances (\$)', number(purchase.advances)),
              ],
            ),
          ),
        ],
      ),
      label('Village', purchase.village),
      label('Bag level', purchase.copraBagLevel),
      label('Vessel', firstText([purchase.veselName, purchase.vesel])),
      label('Island', purchase.island),
      label('Province', purchase.province),
      label('Phone/mobile', purchase.phonemobileNo),
      if (hasValue(purchase.deliveryType) || hasValue(purchase.courierName))
        heading('Delivery details'),
      label('Delivery type', purchase.deliveryType),
      label('Courier name', purchase.courierName),
      if (bags.isNotEmpty) ...[
        heading('Bag details'),
        table(
          ['Bag number', 'Rate/kg', 'Weight kg'],
          [
            for (final bag in bags)
              [
                text(bag.bagNumber),
                money(purchase.rate),
                number(bag.weight, 3),
              ],
          ],
          {
            0: const pw.FlexColumnWidth(1.1),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
        ),
      ],
      if (items.isNotEmpty) heading('Items'),
      for (final item in items) ...[
        if (hasValue(firstText([item.itemName, item.itemCode])))
          pw.Text(
            firstText([item.itemName, item.itemCode]),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        if (item.itemName != null && item.itemCode != item.itemName)
          label('Item code', item.itemCode),
        table(
          ['Qty', 'UOM', 'Amount (\$)'],
          [
            [number(item.qty, 3), text(item.uom), number(item.totalAmount)],
          ],
          {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(.7),
            2: const pw.FlexColumnWidth(1.3),
          },
        ),
      ],
      if (advances.isNotEmpty) ...[
        heading('Advance details'),
        table(
          ['Reference', 'Advance (\$)', 'Allocated (\$)'],
          [
            for (final advance in advances)
              [
                [
                  if (hasValue(advance.referenceName))
                    text(advance.referenceName),
                  // if (hasValue(advance.referenceType))
                  //   'Type: ${text(advance.referenceType)}',
                  if (hasValue(advance.remarks))
                    'Remarks: ${text(advance.remarks)}',
                ].join('\n'),
                number(advance.advanceAmount),
                number(advance.allocatedAmount),
              ],
          ],
          {
            0: const pw.FlexColumnWidth(1.4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.1),
          },
        ),
        if (advances.length > 1) ...[
          if (advances.any((advance) => advance.advanceAmount != null))
            total(
              'Total advance',
              advances.fold<double>(
                0,
                (sum, advance) => sum + (advance.advanceAmount ?? 0),
              ),
            ),
          if (advances.any((advance) => advance.allocatedAmount != null))
            total(
              'Total allocated',
              advances.fold<double>(
                0,
                (sum, advance) => sum + (advance.allocatedAmount ?? 0),
              ),
            ),
        ],
      ],
      pw.Divider(height: 5, thickness: .5),
      total('Total', purchase.totalAmount ?? purchase.grandTotal),
      total('Total deduction', purchase.totalDeduction),
      total('Net amount', purchase.netPayable, emphasized: true),
      if (payments.isNotEmpty || purchase.instantPaid != null) ...[
        heading('Payment information'),
        // if (purchase.instantPaid != null)
        //   label('Instant payment', purchase.instantPaid == 1 ? 'Yes' : 'No'),
        for (var i = 0; i < payments.length; i++) ...[
          if (payments.length > 1) heading('Payment ${i + 1}'),
          label('Payment type', payments[i].paymentType),
          label('From account', payments[i].paymentFrom),
          if (payments[i].paidAmount != null)
            total('Paid amount', payments[i].paidAmount),
          label('Reference no', payments[i].referenceNo),
          label('Reference date', payments[i].referenceDate),
        ],
        if (payments.where((payment) => payment.paidAmount != null).length > 1)
          total(
            'Total paid',
            payments.fold<double>(
              0,
              (sum, payment) => sum + (payment.paidAmount ?? 0),
            ),
          ),
      ],
      total('Outstanding amount', purchase.outstandingBalance),
      pw.SizedBox(height: 5),
      pw.Center(
        child: pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: jsonEncode({
            'receipt': purchase.name,
            'supplier': purchase.supplierName,
            'net_amount': purchase.netPayable,
          }),
          width: 68,
          height: 68,
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Center(
        child: pw.Text(
          'Thank you, please visit again.',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ),
    ];
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          paperWidth,
          double.infinity,
          marginAll: pageMargin,
        ),
        theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
          defaultTextStyle: pw.TextStyle(font: regular, fontSize: 7.5),
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
    return pdf.save();
  }
}
