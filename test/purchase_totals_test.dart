import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/create_point_of_purchase_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/shared/widgets/app_card.dart';
import 'package:cml_si_buying/shared/widgets/app_text_field.dart';

import 'mobile_ui_test.dart' as fixtures show PurchaseData;

void main() {
  testWidgets(
    'shipping, deductions, net payable and summed bag tare update together',
    (tester) async {
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
      Finder input(String label) =>
          find.byWidgetPredicate((w) => w is AppTextField && w.label == label);
      Future<void> fill(String label, String text, [int index = 0]) async {
        final field = input(label).at(index);
        await tester.ensureVisible(field);
        await tester.enterText(field, text);
        await tester.pumpAndSettle();
      }

      String value(String label) {
        final field = find.byWidgetPredicate(
          (w) => w is InputDecorator && w.decoration.labelText == label,
        );
        return (tester.widget<InputDecorator>(field).child as Text).data!;
      }

      await fill('Weight (kg)', '10');
      await fill('Bag tare (kg)', '1.25');
      await fill('Rate/kg *', '10');
      await fill(r'Freight Amount ($)', '3');
      await fill(r'Others ($)', '2');
      await fill(r'Sea Fare ($)', '4');
      await fill(r'Advances Deduction ($)', '5');
      expect(value(r'Ship Payment ($)'), '9.00');
      expect(value(r'Total Amount ($)'), '87.50');
      expect(value(r'Grand Total ($)'), '87.50');
      expect(value(r'Total Deduction ($)'), '9.00');
      expect(value(r'Net Payable ($)'), '73.50');
      expect(value('Tare per bag (kg)'), '1.25');
      expect(input('Tare per bag (kg)'), findsNothing);
      final bagCard = find.byWidgetPredicate(
        (w) => w is AppCard && w.title == 'Bags and weight',
      );
      final add = find.descendant(of: bagCard, matching: find.text('Add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await fill('Weight (kg)', '20', 1);
      await fill('Bag tare (kg)', '2.75', 1);
      expect(value(r'Total Amount ($)'), '260.00');
      expect(value('Tare per bag (kg)'), '4.00');
      expect(value('Net Weight (kg)'), '26.00');
      expect(value(r'Net Payable ($)'), '246.00');
      await fill('Rate/kg *', '2');
      expect(value(r'Grand Total ($)'), '52.00');
      expect(value(r'Net Payable ($)'), '38.00');
      await fill(r'Advances Deduction ($)', '100');
      expect(value(r'Net Payable ($)'), '-57.00');
      final remove = find.byTooltip('Remove Bag 2');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(value('Tare per bag (kg)'), '1.25');
      expect(value(r'Total Amount ($)'), '17.50');
      expect(value(r'Net Payable ($)'), '-91.50');
      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(value(r'Ship Payment ($)'), '0.00');
      expect(value(r'Total Amount ($)'), '0.00');
      expect(value(r'Total Deduction ($)'), '0.00');
      expect(value(r'Net Payable ($)'), '0.00');
      expect(value('Tare per bag (kg)'), '0.00');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
}
