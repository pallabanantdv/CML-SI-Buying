import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/routes/app_router.dart';
import 'package:cml_si_buying/config/routes/route_names.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:cml_si_buying/features/auth/views/login_screen.dart';
import 'package:cml_si_buying/features/dashboard/repositories/static_dashboard_repository.dart';
import 'package:cml_si_buying/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:cml_si_buying/features/dashboard/views/dashboard_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_detail_screen.dart';
import 'package:cml_si_buying/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/shared/navigation/app_bottom_navigation.dart';
import 'package:cml_si_buying/shared/navigation/app_floating_bottom_navigation.dart';

import 'mobile_ui_test.dart' as fixtures;

class _PendingPurchase extends fixtures.PurchaseData {
  final pending = Completer<Map<String, dynamic>>();
  int detailCalls = 0;
  @override
  Future<Map<String, dynamic>> getPointOfPurchase(String name) {
    detailCalls++;
    return pending.future;
  }
}

class _SignedOut extends fixtures.AccountData {
  @override
  Future<bool> restoreSession() async => false;
}

void main() {
  testWidgets(
    'real shell switches rapidly during pending detail; bar stays still; request stays single',
    (tester) async {
      final auth = AuthViewModel(fixtures.AccountData());
      await auth.login('buyer@example.com', 'test');
      final data = _PendingPurchase();
      final purchases = PointOfPurchaseViewModel(data);
      final dashboard = DashboardViewModel(const StaticDashboardRepository());
      final suppliers = SupplierViewModel(fixtures.SupplierData());
      final profile = ProfileViewModel(fixtures.ProfileData());
      final router = createAppRouter(auth)..goNamed(RouteNames.pointOfPurchase);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: purchases),
            ChangeNotifierProvider.value(value: dashboard),
            ChangeNotifierProvider.value(value: suppliers),
            ChangeNotifierProvider.value(value: profile),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(AppFloatingBottomNavigation));
      unawaited(
        router.pushNamed(
          RouteNames.pointOfPurchaseDetail,
          pathParameters: {'documentName': 'POP-PENDING'},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.bySemanticsLabel('Loading purchase details...'),
        findsOneWidget,
      );
      expect(data.detailCalls, 1);
      for (final label in ['Supplier', 'Dashboard', 'Profile', 'Purchase']) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getRect(find.byType(AppFloatingBottomNavigation)), bar);
        final navigation = tester.widget<AppBottomNavigation>(
          find.byType(AppBottomNavigation),
        );
        expect(
          AppBottomNavigation
              .items[navigation.navigationShell.currentIndex]
              .label,
          label,
        );
      }
      expect(find.byType(PointOfPurchaseDetailScreen), findsOneWidget);
      expect(data.detailCalls, 1);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      data.pending.complete({
        'name': 'POP-PENDING',
        'supplier_name1': 'Loaded after back',
      });
      await tester.pumpAndSettle();
      expect(find.text('Purchases'), findsOneWidget);
      expect(data.calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      auth.dispose();
      purchases.dispose();
      dashboard.dispose();
      suppliers.dispose();
      profile.dispose();
    },
  );

  testWidgets(
    'splash chooses login; authenticated redirect fades into the existing shell',
    (tester) async {
      final auth = AuthViewModel(_SignedOut());
      await auth.restoreSession();
      final dashboard = DashboardViewModel(const StaticDashboardRepository());
      final router = createAppRouter(auth);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: dashboard),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2300));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      await auth.login('buyer@example.com', 'test');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DashboardScreen), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        RoutePaths.dashboard,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      auth.dispose();
      dashboard.dispose();
    },
  );
}
