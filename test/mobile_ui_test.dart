import 'package:cml_si_buying/config/routes/app_router.dart';
import 'package:cml_si_buying/config/routes/route_names.dart';
import 'package:cml_si_buying/shared/navigation/app_bottom_navigation.dart';
import 'package:cml_si_buying/features/dashboard/repositories/static_dashboard_repository.dart';
import 'package:cml_si_buying/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:cml_si_buying/shared/widgets/app_dropdown.dart';
import 'package:cml_si_buying/features/settings/views/settings_screen.dart';

import 'package:cml_si_buying/shared/widgets/app_empty_state.dart';
import 'package:cml_si_buying/shared/widgets/app_error_widget.dart';
import 'package:cml_si_buying/shared/widgets/app_loader.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';

import 'package:cml_si_buying/shared/widgets/app_text_field.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/config/theme/theme_provider.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/core/storage/preferences_service.dart';
import 'package:cml_si_buying/features/auth/models/login_request.dart';
import 'package:cml_si_buying/features/auth/models/user_model.dart';
import 'package:cml_si_buying/features/auth/repositories/auth_repository.dart';
import 'package:cml_si_buying/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:cml_si_buying/features/auth/views/login_screen.dart';
import 'package:cml_si_buying/features/dashboard/views/dashboard_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/point_of_purchase_model.dart';
import 'package:cml_si_buying/features/point_of_purchase/models/supplier_advance.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_detail_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/create_point_of_purchase_screen.dart';
import 'package:cml_si_buying/features/supplier/models/supplier_model.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/add_supplier_screen.dart';
import 'package:cml_si_buying/features/supplier/views/create_supplier_screen.dart';
import 'package:cml_si_buying/features/profile/models/profile_model.dart';
import 'package:cml_si_buying/features/profile/repositories/profile_repository.dart';
import 'package:cml_si_buying/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:cml_si_buying/features/profile/views/profile_screen.dart';

FrappeResourceApi api() => FrappeResourceApi(
  ApiClient(DioClient(dio: Dio(BaseOptions(baseUrl: 'https://example.com')))),
);

class PurchaseData extends PointOfPurchaseRepository {
  PurchaseData({this.records}) : super(api());
  final List<PointOfPurchaseModel>? records;
  int calls = 0;
  Map<String, dynamic>? created;
  List<SupplierAdvance> supplierAdvances = const [];
  @override
  Future<List<SupplierAdvance>> getSupplierAdvances(String supplier) async =>
      supplierAdvances;
  @override
  Future<Map<String, dynamic>> createPointOfPurchase(
    Map<String, dynamic> fields,
  ) async {
    created = Map.of(fields);
    throw const AppException('Test server refused save');
  }

  @override
  Future<List<PointOfPurchaseModel>> getPointOfPurchases() async {
    calls++;
    if (records != null) return records!;
    return List.generate(
      50,
      (i) => PointOfPurchaseModel(
        name: 'POP-2026-$i',
        supplierName: 'Solomon Islands Agricultural Producers Cooperative',
        collectionLocation: 'Central collection warehouse',
        purchaseDateTime: '2026-11-03 10:30',
        netPayable: 1234567890.12,
        grossWeight: 1500,
        docStatus: i % 3,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> getPointOfPurchase(String name) async => {
    'name': name,
    'supplier_name1': 'Solomon Islands Agricultural Producers Cooperative',
    'supplier_name': 'SUP-0001',
    'docstatus': 1,
    'net_payable': 1234567890.12,
    'grand_total': 1234567890.12,
    'province': 'Western Province',
    'collection_location': 'Central collection warehouse',
    'owner': 'buyer@example.com',
    'supplier_pop_item': [
      {'item_code': 'COPRA-1', 'qty': 1500, 'rate': 20, 'total_amount': 30000},
    ],
  };
  @override
  Future<List<Map<String, dynamic>>> getSupplierOptions() async => [
    {
      'value': 'S1',
      'title': 'Supplier One',
      'label': 'Supplier One',
      'village': 'Village',
      'province': 'Province',
      'supplier_type': 'Company',
    },
  ];
  @override
  Future<List<Map<String, dynamic>>> getItemOptions() async => [
    {
      'value': 'I1',
      'title': 'RAW COPRA',
      'label': 'RAW COPRA',
      'stock_uom': 'Kg',
    },
    {
      'value': 'RAW-001',
      'title': 'COCOA BEAN',
      'label': 'COCOA BEAN',
      'stock_uom': 'MT',
    },
  ];
  @override
  Future<List<Map<String, dynamic>>> getJournalEntryOptions() async => [];
  @override
  Future<List<Map<String, dynamic>>> getLinkOptions(
    String doctype, {
    List<String> fields = const ['name'],
    String titleField = 'name',
  }) async => switch (doctype) {
    'UOM' => [
      {'value': 'Kg', 'title': 'Kg', 'label': 'Kg'},
    ],
    'Warehouse' => [
      {'value': 'W1', 'title': 'Main warehouse', 'label': 'Main warehouse'},
    ],
    'Company' => [
      {'value': 'C1', 'title': 'CAML', 'label': 'CAML'},
    ],
    'Mode of Payment' => [
      {'value': 'Cash', 'title': 'Cash', 'label': 'Cash'},
    ],
    _ => [],
  };
}

class SupplierData extends SupplierRepository {
  Map<String, dynamic>? created;
  @override
  Future<SupplierModel> createSupplier(Map<String, dynamic> fields) async {
    created = Map.of(fields);
    return SupplierModel(
      id: 'NEW-SUPPLIER',
      name: fields['supplier_name'] as String,
    );
  }

  SupplierData() : super(api());
  @override
  Future<List<SupplierModel>> getSuppliers() async => [
    const SupplierModel(
      id: 'SUP-0001',
      name: 'Solomon Islands Agricultural Producers Cooperative',
      type: 'Company',
      group: 'Agriculture',
      village: 'Central village',
      phone: '+677 1234567',
      email: 'supplier.with.a.long.address@example.com',
    ),
  ];
}

class AccountData implements AuthRepositoryContract {
  @override
  Future<UserModel> login(LoginRequest request) async =>
      const UserModel(id: 'buyer@example.com', fullName: 'Alex');
  @override
  Future<void> logout() async {}
  @override
  Future<void> clearLocalSession() async {}
  @override
  Future<UserModel> currentUser() async =>
      const UserModel(id: 'buyer@example.com', fullName: 'Alex');
  @override
  Future<bool> restoreSession() async => true;
}

class ProfileData extends ProfileRepository {
  ProfileData() : super(api());
  @override
  Future<ProfileModel> getProfile(String email) async => ProfileModel(
    fields: {
      'full_name': 'Alexandra Purchasing Department Administrator',
      'email': email,
      'enabled': 1,
      'username': 'alexandra',
      'user_type': 'System User',
      'language': 'en',
      'time_zone': 'Pacific/Guadalcanal',
      'last_login': '2026-11-03',
    },
    roles: [
      'Buying Manager',
      'Purchase User',
      'A very long role name for accessibility testing',
      'Stock User',
      'Accounts User',
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final font in ['Alike Angular', 'Poppins']) {
      final loader = FontLoader(font)
        ..addFont(
          rootBundle.load(
            font == 'Alike Angular'
                ? 'assets/fonts/AlikeAngular-Regular.ttf'
                : 'assets/fonts/Poppins-SemiBold.ttf',
          ),
        );
      await loader.load();
    }
  });
  Future<Widget> host(
    Widget screen,
    double scale,
    ThemeData theme,
    GlobalKey boundary, {
    PurchaseData? purchaseData,
  }) async {
    final auth = AuthViewModel(AccountData());
    await auth.login('buyer@example.com', 'test');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(const StaticDashboardRepository()),
        ),
        ChangeNotifierProvider(create: (_) => auth),
        ChangeNotifierProvider(
          create: (_) =>
              PointOfPurchaseViewModel(purchaseData ?? PurchaseData()),
        ),
        ChangeNotifierProvider(
          create: (_) => SupplierViewModel(SupplierData()),
        ),
        ChangeNotifierProvider(create: (_) => ProfileViewModel(ProfileData())),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(PreferencesService(awaitedPrefs!)),
        ),
      ],
      child: RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
  }

  final screens = <String, Widget Function()>{
    'dashboard': () => const DashboardScreen(),
    'purchases': () => const PointOfPurchaseScreen(),
    'purchase_detail': () =>
        const PointOfPurchaseDetailScreen(documentName: 'POP-2026-1'),
    'suppliers': () => const AddSupplierScreen(),
    'supplier_form': () => const CreateSupplierScreen(),
    'purchase_form': () => const CreatePointOfPurchaseScreen(),
    'profile': () => const ProfileScreen(),
    'settings': () => const SettingsScreen(),
    'login': () => const LoginScreen(),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits phones, large text and both themes', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({});
      awaitedPrefs = await SharedPreferences.getInstance();
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        for (final scale in [1.0, 2.0]) {
          for (final theme in [AppTheme.light, AppTheme.dark]) {
            final boundary = GlobalKey();
            await tester.pumpWidget(
              await host(entry.value(), scale, theme, boundary),
            );
            await tester.pumpAndSettle();
            expect(find.bySemanticsLabel('CAML logo'), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason:
                  '${entry.key} width=$width scale=$scale brightness=${theme.brightness}',
            );
            // Layout every section, including fields far below the fold.
            final scrolls = find.byType(Scrollable);
            for (var step = 0; step < 3; step++) {
              if (scrolls.evaluate().isNotEmpty) {
                await tester.drag(scrolls.first, const Offset(0, -600));
                await tester.pumpAndSettle();
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '${entry.key} scrolled width=$width scale=$scale',
                );
              }
            }
            if (width == 390 &&
                scale == 1 &&
                theme.brightness == Brightness.light) {
              if (scrolls.evaluate().isNotEmpty) {
                final state = tester.state<ScrollableState>(scrolls.first);
                state.position.jumpTo(0);
                await tester.pumpAndSettle();
              }
              await tester.runAsync(() async {
                await precacheImage(
                  const AssetImage('assets/images/CAML Logo.jpg.jpeg'),
                  tester.element(find.byType(Scaffold).first),
                );
              });
              await tester.pumpAndSettle();
              await tester.runAsync(() async {
                final pixels =
                    await (boundary.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage(pixelRatio: 1);
                final bytes = await pixels.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File('build/mobile-previews/${entry.key}_390.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                pixels.dispose();
              });
            }
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    });
  }
  testWidgets(
    'labelled tabs, nested back, and shared first-load cache work together',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 760);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthViewModel(AccountData());
      await auth.login('buyer@example.com', 'test');
      final data = PurchaseData();
      final router = createAppRouter(auth)..goNamed(RouteNames.dashboard);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  DashboardViewModel(const StaticDashboardRepository()),
            ),
            ChangeNotifierProvider(create: (_) => auth),
            ChangeNotifierProvider(
              create: (_) => PointOfPurchaseViewModel(data),
            ),
            ChangeNotifierProvider(
              create: (_) => SupplierViewModel(SupplierData()),
            ),
            ChangeNotifierProvider(
              create: (_) => ProfileViewModel(ProfileData()),
            ),
            ChangeNotifierProvider(
              create: (_) => ThemeProvider(PreferencesService(prefs)),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(
        data.calls,
        0,
        reason: 'Static dashboard must not fetch ERP purchases',
      );
      Future<void> tapDashboardAction(String label) async {
        final action = find.text(label).hitTestable();
        await tester.scrollUntilVisible(
          action,
          250,
          scrollable: find
              .descendant(
                of: find.byType(DashboardScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
      }

      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNavigation),
          matching: find.bySemanticsLabel('New purchase'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CreatePointOfPurchaseScreen), findsOneWidget);
      expect(find.byType(AppBottomNavigation), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(data.calls, 0);
      await tester.tap(find.bySemanticsLabel('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      final settingsLink = find.text('Settings').hitTestable();
      await tester.scrollUntilVisible(
        settingsLink,
        250,
        scrollable: find
            .descendant(
              of: find.byType(ProfileScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(settingsLink);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Dark'));
      await tester.pumpAndSettle();
      expect(prefs.getString('theme_mode'), 'dark');
      final restoredTheme = ThemeProvider(PreferencesService(prefs));
      expect(restoredTheme.themeMode, ThemeMode.dark);
      restoredTheme.dispose();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Light'));
      await tester.pumpAndSettle();
      expect(prefs.getString('theme_mode'), 'light');
      await tester.tap(find.widgetWithText(ChoiceChip, 'System'));
      await tester.pumpAndSettle();
      expect(prefs.getString('theme_mode'), 'system');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(data.calls, 0);
      router.goNamed(
        RouteNames.pointOfPurchaseDetail,
        pathParameters: {'documentName': 'POP-2026-1'},
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
            .navigationShell
            .currentIndex,
        1,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Purchases'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Dashboard'));
      await tester.pumpAndSettle();
      await tapDashboardAction('View purchases');
      expect(data.calls, 1);
      expect(tester.takeException(), isNull);
      router.pushNamed(
        RouteNames.pointOfPurchaseDetail,
        pathParameters: {'documentName': 'POP-2026-1'},
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Purchases'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      await tapDashboardAction('Add purchase');
      expect(find.byType(CreatePointOfPurchaseScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tapDashboardAction('View suppliers');
      await tester.tap(find.text('Add supplier'));
      await tester.pumpAndSettle();
      expect(find.text('Save supplier'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Suppliers'), findsOneWidget);
      await tester.tap(find.text('Add supplier'));
      await tester.pumpAndSettle();
      final supplierData = contextRepository(tester);
      final name = find.byWidgetPredicate(
        (widget) => widget is AppTextField && widget.label == 'Supplier name',
      );
      await tester.ensureVisible(name);
      await tester.enterText(name, 'New Supplier');
      final email = find.widgetWithText(TextFormField, 'Email address');
      await tester.ensureVisible(email);
      await tester.enterText(email, 'new@example.com');
      await tester.tap(find.text('Save supplier'));
      await tester.pumpAndSettle();
      expect(supplierData.created, {
        'supplier_name': 'New Supplier',
        'supplier_group': 'Other',
        'supplier_type': 'Company',
        'country': 'Solomon Islands',
        'email_id': 'new@example.com',
      });
      expect(find.text('Suppliers'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.goNamed(RouteNames.settings);
      await tester.pumpAndSettle();
      final licenses = find.text('Open-source licenses').hitTestable();
      await tester.scrollUntilVisible(
        licenses,
        250,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(licenses);
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      final signOut = find.text('Sign out').hitTestable();
      await tester.scrollUntilVisible(
        signOut,
        -250,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(signOut);
      await tester.pumpAndSettle();
      expect(auth.isAuthenticated, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    },
  );

  testWidgets(
    'purchase form preserves calculations, payload and API error feedback',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      awaitedPrefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        await host(
          const CreatePointOfPurchaseScreen(),
          1,
          AppTheme.light,
          GlobalKey(),
        ),
      );
      await tester.pumpAndSettle();
      final data =
          tester
                  .element(find.byType(CreatePointOfPurchaseScreen))
                  .read<PointOfPurchaseViewModel>()
                  .repository
              as PurchaseData;
      data.supplierAdvances = const [
        SupplierAdvance(
          name: 'PAY-TEST',
          paidMinor: 100000,
          unallocatedMinor: 100000,
        ),
      ];
      Future<void> select(String label, String option) async {
        final field = find.byWidgetPredicate(
          (widget) => widget is AppDropdown<String> && widget.label == label,
        );
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }

      Future<void> fill(String label, String value) async {
        final field = find.byWidgetPredicate(
          (widget) => widget is AppTextField && widget.label == label,
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      await select('Supplier Code *', 'Supplier One');
      await select('Company *', 'CAML');
      await select('Product Type', 'Copra');
      await select('Product Type', 'Cocoa');
      await fill('Weight (kg)', '25');
      await fill('Rate/kg *', '10');
      await fill(r'Freight Amount ($)', '3');
      await fill(r'Others ($)', '2');
      await fill(r'Sea Fare ($)', '4');
      await fill('Bag tare (kg)', '1.5');
      await fill(r'Advances Deduction ($)', '5');
      await select('Mode of Payment', 'Cash');
      await fill(r'Payment Amount ($)', '236');
      await select('Default Accepted Warehouse *', 'Main warehouse');
      await tester.tap(find.text('Save purchase'));
      await tester.pumpAndSettle();
      expect(data.created, isNotNull);
      expect(data.created!['supplier_name'], 'S1');
      expect(data.created!['company'], 'C1');
      expect(data.created!['custom_product_type'], 'Cocoa');
      expect(data.created!['grand_total'], 250);
      expect(data.created!['total_amount'], 250);
      expect(data.created!['ship_payment'], 9);
      expect(data.created!['total_deduction'], 9);
      expect(data.created!['tare15kgsbag'], 1.5);
      expect(data.created!['net_payable'], 236);
      expect(data.created!['advances'], 5);
      expect(data.created!.containsKey('supplier_advance_allocation'), isFalse);
      expect(data.created!['advance'], [
        {
          'reference_name': 'PAY-TEST',
          'remarks': '',
          'advance_amount': 1000.0,
          'allocated_amount': 5.0,
        },
      ]);
      expect(data.created!['gross_weight'], 25);
      expect(data.created!['net_qty'], 0.025);
      expect((data.created!['supplier_pop_item'] as List).single, {
        'item_code': 'RAW-001',
        'item_name': 'COCOA BEAN',
        'qty': 0.025,
        'uom': 'MT',
        'rate': 10000.0,
        'total_amount': 250.0,
      });
      expect(find.text('Test server refused save'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('portrait layouts remain scrollable when rotated', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    awaitedPrefs = await SharedPreferences.getInstance();
    for (final screen in screens.values) {
      await tester.pumpWidget(
        await host(screen(), 2, AppTheme.dark, GlobalKey()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    for (final state in [
      const AppEmptyState(
        title: 'No records available',
        description: 'Try refreshing your purchasing workspace.',
      ),
      AppErrorWidget(
        message:
            'The server could not complete this request. Please try again.',
        onRetry: () {},
      ),
      const AppLoader(label: 'Loading your purchasing workspace...'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(844, 390),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(body: SizedBox(height: 160, child: state)),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('purchase search and status filters operate on fetched records', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    awaitedPrefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      await host(const PointOfPurchaseScreen(), 1, AppTheme.light, GlobalKey()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Submitted'));
    await tester.pumpAndSettle();
    expect(find.text('17 recent purchases'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'POP-2026-1');
    await tester.pumpAndSettle();
    expect(find.text('5 recent purchases'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no such purchase');
    await tester.pumpAndSettle();
    expect(find.text('No matching purchases'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('supplier and product dropdowns combine with search and status', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    awaitedPrefs = await SharedPreferences.getInstance();
    final data = PurchaseData(
      records: [
        const PointOfPurchaseModel(
          name: 'POP-A',
          supplierName: ' Supplier Alpha ',
          productType: ' Copra ',
          docStatus: 1,
        ),
        const PointOfPurchaseModel(
          name: 'POP-B',
          supplierName: 'Supplier Alpha',
          productType: 'Cocoa',
          docStatus: 0,
        ),
        const PointOfPurchaseModel(
          name: 'POP-C',
          supplierName: 'Supplier Beta',
          productType: 'Copra',
          docStatus: 1,
        ),
        const PointOfPurchaseModel(
          name: 'POP-D',
          supplierId: 'SUP-004',
          docStatus: 0,
        ),
      ],
    );
    await tester.pumpWidget(
      await host(
        const PointOfPurchaseScreen(),
        1,
        AppTheme.light,
        GlobalKey(),
        purchaseData: data,
      ),
    );
    await tester.pumpAndSettle();
    Future<void> select(String label, String option) async {
      final dropdown = find.byWidgetPredicate(
        (widget) => widget is AppDropdown<String> && widget.label == label,
      );
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      final optionRow = find.widgetWithText(ListTile, option);
      expect(optionRow, findsOneWidget);
      await tester.tap(optionRow);
      await tester.pumpAndSettle();
    }

    expect(find.text('4 recent purchases'), findsOneWidget);
    await select('Supplier name', 'Supplier Alpha');
    expect(find.text('2 recent purchases'), findsOneWidget);
    await select('Product type', 'Copra');
    expect(find.text('1 recent purchase'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Draft'));
    await tester.pumpAndSettle();
    expect(find.text('No matching purchases'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await select('Supplier name', 'All suppliers');
    expect(find.text('2 recent purchases'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'POP-C');
    await tester.pumpAndSettle();
    expect(find.text('1 recent purchase'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await select('Product type', 'All types');
    expect(find.text('4 recent purchases'), findsOneWidget);
    await select('Supplier name', 'SUP-004');
    expect(find.text('1 recent purchase'), findsOneWidget);
    final vm = tester
        .element(find.byType(PointOfPurchaseScreen))
        .read<PointOfPurchaseViewModel>();
    data.records!.removeLast();
    await vm.loadPointOfPurchases();
    await tester.pumpAndSettle();
    expect(find.text('No matching purchases'), findsOneWidget);
    await select('Supplier name', 'All suppliers');
    expect(find.text('3 recent purchases'), findsOneWidget);
    expect(data.calls, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'dashboard/list cache is reset between authenticated sessions',
    () async {
      final data = PurchaseData();
      final vm = PointOfPurchaseViewModel(data);
      await vm.ensureLoaded();
      await vm.ensureLoaded();
      expect(data.calls, 1);
      expect(vm.records.length, 50);
      vm.resetSession();
      expect(vm.records, isEmpty);
      await vm.ensureLoaded();
      expect(data.calls, 2);
      vm.dispose();
    },
  );

  testWidgets('supplier form keeps validation and save visible with keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    SharedPreferences.setMockInitialValues({});
    awaitedPrefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      await host(const CreateSupplierScreen(), 1, AppTheme.light, GlobalKey()),
    );
    await tester.pumpAndSettle();
    final email = find.widgetWithText(TextFormField, 'Email address');
    await tester.ensureVisible(email);
    await tester.enterText(email, 'invalid-email');
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.text('Save supplier')).dy, lessThan(420));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Save supplier'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('This field is required.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

SharedPreferences? awaitedPrefs;

SupplierData contextRepository(WidgetTester tester) =>
    tester
            .element(find.byType(CreateSupplierScreen))
            .read<SupplierViewModel>()
            .repository
        as SupplierData;
