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
    'bag count creates rows, preserves weights and stays synced with row actions and reset',
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
      Future<void> fill(Finder field, String value) async {
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      final count = input('No. of Bag');
      String countText() => tester.widget<AppTextField>(count).controller!.text;
      String grossWeight() =>
          (tester
                      .widget<InputDecorator>(
                        find.byWidgetPredicate(
                          (w) =>
                              w is InputDecorator &&
                              w.decoration.labelText == 'Gross Weight (kg)',
                        ),
                      )
                      .child
                  as Text)
              .data!;
      expect(countText(), '1');
      await fill(count, '3');
      expect(input('Bag number'), findsNWidgets(3));
      await fill(input('Weight (kg)').at(0), '10');
      await fill(input('Weight (kg)').at(1), '20');
      expect(grossWeight(), '30.00');
      await fill(count, '1');
      expect(input('Bag number'), findsOneWidget);
      expect(grossWeight(), '10.00');
      await fill(count, '3');
      expect(input('Bag number'), findsNWidgets(3));
      expect(
        tester
            .widget<AppTextField>(input('Weight (kg)').at(1))
            .controller!
            .text,
        '20',
      );
      expect(grossWeight(), '30.00');
      for (final invalid in ['', '0', '1001']) {
        await fill(count, invalid);
        expect(input('Bag number'), findsNWidgets(3));
        expect(
          find.text('Enter a whole number from 1 to 1000.'),
          findsOneWidget,
        );
      }
      await fill(count, '2');
      final card = find.byWidgetPredicate(
        (w) => w is AppCard && w.title == 'Bags and weight',
      );
      final add = find.descendant(of: card, matching: find.text('Add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(countText(), '3');
      expect(input('Bag number'), findsNWidgets(3));
      final remove = find.byTooltip('Remove Bag 2');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(countText(), '2');
      expect(input('Bag number'), findsNWidgets(2));
      expect(grossWeight(), '10.00');
      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(countText(), '1');
      expect(input('Bag number'), findsOneWidget);
      expect(grossWeight(), '0.00');
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
