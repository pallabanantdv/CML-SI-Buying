import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/config/theme/theme_provider.dart';
import 'package:cml_si_buying/core/storage/preferences_service.dart';
import 'package:cml_si_buying/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:cml_si_buying/features/dashboard/views/dashboard_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_detail_screen.dart';
import 'package:cml_si_buying/features/supplier/views/add_supplier_screen.dart';
import 'package:cml_si_buying/features/profile/views/profile_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/widgets/app_purchase_card.dart';
import 'package:cml_si_buying/shared/widgets/app_card.dart';

import 'mobile_ui_test.dart' as fixtures;

import 'package:cml_si_buying/features/dashboard/repositories/static_dashboard_repository.dart';
import 'package:cml_si_buying/features/dashboard/viewmodels/dashboard_viewmodel.dart';

void main() {
  testWidgets('record card geometry and visible density with identical data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in {
      'Alike Angular': 'assets/fonts/AlikeAngular-Regular.ttf',
      'Poppins': 'assets/fonts/Poppins-SemiBold.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    const label = String.fromEnvironment(
      'DENSITY_LABEL',
      defaultValue: 'current',
    );
    final metrics = <String, Map<String, num>>{};
    final screens = <String, Widget>{
      'purchases': const PointOfPurchaseScreen(),
      'supplier': const AddSupplierScreen(),
      'detail': const PointOfPurchaseDetailScreen(documentName: 'POP-2026-1'),
      'profile': const ProfileScreen(),
      'dashboard': const DashboardScreen(),
    };
    for (final entry in screens.entries) {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthViewModel(fixtures.AccountData());
      await auth.login('buyer@example.com', 'test');
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  DashboardViewModel(const StaticDashboardRepository()),
            ),
            ChangeNotifierProvider(create: (_) => auth),
            ChangeNotifierProvider(
              create: (_) => PointOfPurchaseViewModel(fixtures.PurchaseData()),
            ),
            ChangeNotifierProvider(
              create: (_) => SupplierViewModel(fixtures.SupplierData()),
            ),
            ChangeNotifierProvider(
              create: (_) => ProfileViewModel(fixtures.ProfileData()),
            ),
            ChangeNotifierProvider(
              create: (_) => ThemeProvider(PreferencesService(prefs)),
            ),
          ],
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: entry.value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final card = find.byType(AppCard).first;
      var visible = 0;
      for (final item in find.byType(AppPurchaseCard).evaluate()) {
        final box = item.renderObject! as RenderBox;
        final top = box.localToGlobal(Offset.zero).dy;
        if (top >= 60 && top + box.size.height <= 844) visible++;
      }
      metrics[entry.key] = {
        'firstCardHeight': tester.getSize(card).height,
        'firstCardTop': tester.getTopLeft(card).dy,
        'fullyVisiblePurchases': visible,
      };
      await tester.runAsync(() async {
        final pixels =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
        final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/compact-density/$label/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        pixels.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    await tester.runAsync(() async {
      final file = File('build/compact-density/$label/metrics.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metrics),
      );
    });
  });
}
