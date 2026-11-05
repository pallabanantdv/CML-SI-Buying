import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/calculated_purchase_item.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/create_point_of_purchase_screen.dart';
import 'package:cml_si_buying/shared/widgets/app_card.dart';
import 'package:cml_si_buying/shared/widgets/app_dropdown.dart';
import 'package:cml_si_buying/shared/widgets/app_text_field.dart';

import 'mobile_ui_test.dart' as fixtures;

void main() {
  test('100 kg at 100/kg becomes 0.1 MT at 100000/MT with the same total', () {
    const item = CalculatedPurchaseItem(
      itemCode: 'RAW-001',
      itemName: 'COCOA BEAN',
      weightKg: 100,
      ratePerKg: 100,
    );
    expect(item.toJson(), {
      'item_code': 'RAW-001',
      'item_name': 'COCOA BEAN',
      'qty': 0.1,
      'uom': 'MT',
      'rate': 100000.0,
      'total_amount': 10000.0,
    });
    const small = CalculatedPurchaseItem(
      itemCode: 'I1',
      itemName: 'Copra',
      weightKg: 0.5,
      ratePerKg: 2.5,
    );
    expect(small.quantityMt, 0.0005);
    expect(small.totalAmount, 1.25);
  });

  test(
    'product matching uses actual ERP identifiers and rejects ambiguous names',
    () {
      final options = [
        {'value': 'RAW-001', 'title': 'RAW-001 - COCOA BEAN'},
        {'value': 'COP-1', 'title': 'RAW COPRA'},
        {'value': 'OTHER', 'title': 'Copra'},
      ];
      expect(
        CalculatedPurchaseItem.matchProduct(options, 'Cocoa')?['value'],
        'RAW-001',
      );
      expect(
        CalculatedPurchaseItem.matchProduct(options, 'Copra')?['value'],
        'COP-1',
      );
      expect(CalculatedPurchaseItem.matchProduct(options, null), isNull);
      expect(CalculatedPurchaseItem.matchProduct([], 'Cocoa'), isNull);
      expect(CalculatedPurchaseItem.itemNameForProduct('Copra'), 'RAW COPRA');
      expect(CalculatedPurchaseItem.itemNameForProduct('Cocoa'), 'COCOA BEAN');
      expect(
        CalculatedPurchaseItem.matchProduct([
          {'value': 'A', 'title': 'Copra'},
          {'value': 'B', 'title': 'Cocoa'},
        ], 'Copra'),
        isNull,
      );
      expect(
        CalculatedPurchaseItem.matchProduct([
          {'value': 'A', 'title': 'RAW COPRA'},
          {'value': 'B', 'title': 'RAW COPRA'},
        ], 'Copra'),
        isNull,
      );
      expect(
        CalculatedPurchaseItem.matchProduct([
          {'value': 'A', 'title': 'Cocoa Beans'},
          {'value': 'B', 'title': 'Cocoa Nibs'},
        ], 'Cocoa'),
        isNull,
      );
      expect(
        CalculatedPurchaseItem.matchProduct([
          {'value': 'A', 'title': 'COCOA BEAN'},
          {'value': 'B', 'title': 'Cocoa'},
          {'value': 'C', 'title': 'Cocoa Nibs'},
        ], 'Cocoa')?['value'],
        'A',
      );
    },
  );

  testWidgets(
    'bag adds, weight edits, rate changes and removals recalculate one read-only MT row',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 840);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = PointOfPurchaseViewModel(fixtures.PurchaseData());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CreatePointOfPurchaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> product(String name) async {
        final field = find.byWidgetPredicate(
          (w) => w is AppDropdown<String> && w.label == 'Product Type',
        );
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(name).last);
        await tester.pumpAndSettle();
      }

      Finder input(String label) =>
          find.byWidgetPredicate((w) => w is AppTextField && w.label == label);
      Future<void> fill(Finder field, String value) async {
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      DataTable table() => tester.widget<DataTable>(find.byType(DataTable));
      String textCell(int index) =>
          (table().rows.single.cells[index].child as Text).data!;
      await product('Cocoa');
      await fill(input('Weight (kg)'), '50');
      final bags = find.byWidgetPredicate(
        (w) => w is AppCard && w.title == 'Bags and weight',
      );
      final add = find.descendant(of: bags, matching: find.text('Add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await fill(input('Weight (kg)').at(1), '50');
      await fill(input('Rate/kg *'), '100');
      expect(textCell(3), '0.10000');
      expect(textCell(4), 'MT');
      expect(textCell(5), r'$ 100,000.00');
      expect(textCell(6), r'$ 10,000.00');
      final itemCard = find.byWidgetPredicate(
        (w) => w is AppCard && w.title == 'Supplier POP Item',
      );
      expect(
        find.descendant(of: itemCard, matching: find.byType(AppTextField)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: itemCard,
          matching: find.byType(AppDropdown<String>),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: itemCard, matching: find.text('Add')),
        findsNothing,
      );
      await fill(input('Weight (kg)').first, '75');
      expect(textCell(3), '0.12500');
      expect(textCell(6), r'$ 12,500.00');
      await fill(input('Rate/kg *'), '200');
      expect(textCell(5), r'$ 200,000.00');
      expect(textCell(6), r'$ 25,000.00');
      final remove = find.byTooltip('Remove Bag 2');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(textCell(3), '0.07500');
      expect(textCell(6), r'$ 15,000.00');
      await product('Copra');
      expect((table().rows.single.cells[1].child as SelectableText).data, 'I1');
      expect(textCell(2), 'RAW COPRA');
      expect(textCell(3), '0.07500');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
}
