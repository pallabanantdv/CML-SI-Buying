import 'package:flutter_test/flutter_test.dart';

import 'package:cml_si_buying/shared/navigation/app_bottom_navigation.dart';

void main() {
  test('main navigation exposes exactly the four requested modules', () {
    expect(AppBottomNavigation.items.map((item) => item.label).toList(), [
      'Dashboard',
      'Purchase',
      'Supplier',
      'Profile',
    ]);
  });
}
