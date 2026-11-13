import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cml_si_buying/shared/widgets/app_dropdown.dart';

void main() {
  testWidgets('selected values can be cleared in both dropdown paths', (
    tester,
  ) async {
    for (final itemCount in [2, 10]) {
      String? selectedValue = 'option-0';
      final items = List.generate(
        itemCount,
        (index) => DropdownMenuItem<String>(
          value: 'option-$index',
          child: Text('Option $index'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppDropdown<String>(
                value: selectedValue,
                items: items,
                onChanged: (value) => setState(() => selectedValue = value),
                label: 'Option',
              ),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Clear selection'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear selection'));
      await tester.pumpAndSettle();

      expect(selectedValue, isNull);
      expect(find.byTooltip('Clear selection'), findsNothing);
    }
  });
}
