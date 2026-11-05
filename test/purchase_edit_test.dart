import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/routes/route_names.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_method_api.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/create_point_of_purchase_screen.dart';
import 'package:cml_si_buying/features/point_of_purchase/views/point_of_purchase_detail_screen.dart';
import 'package:cml_si_buying/shared/widgets/app_text_field.dart';
import 'package:cml_si_buying/shared/widgets/app_dropdown.dart';

import 'mobile_ui_test.dart' as fixtures show PurchaseData;
import 'purchase_submission_test.dart' show Adapter, response;

Map<String, dynamic> record() => {
  'name': 'POP/EDIT-1',
  'doctype': 'Supplier Point Of Purchase',
  'docstatus': 0,
  'modified': '2026-11-04 10:20:00',
  'supplier_name': 'S1',
  'supplier_name1': 'Original supplier',
  'supplier_type': 'Company',
  'village': 'Original village',
  'province': 'Original province',
  'company': 'C2',
  'custom_product_type': 'Copra',
  'delivery_type': 'Courier',
  'collection_location': 'W1',
  'default_accepted_warehouse': 'W1',
  'courier_name': 'Original courier',
  'date': '2026-11-04',
  'time': '13:45:00',
  'rate': 10,
  'freight': 3,
  'advances': 5,
  'payment_amount': 252,
  'mode_of_payment': 'Cash',
  'instant_paid': 1,
  'gst': 7,
  'paid': 1,
  'total_bag': [
    {
      'name': 'BAG-1',
      'bag_number': 'Bag - 1',
      'weight': 10,
      'tarebagkg': 1,
      'custom_bag': 'keep',
    },
    {'name': 'BAG-2', 'bag_number': 'Bag - 2', 'weight': 15, 'tarebagkg': 2},
  ],
  'supplier_pop_item': [
    {
      'name': 'ITEM-1',
      'item_code': 'I1',
      'item_name': 'RAW COPRA',
      'qty': 0.025,
      'rate': 10000,
      'uom': 'MT',
      'total_amount': 250,
      'custom_item': 'keep',
    },
    {
      'name': 'ITEM-2',
      'item_code': 'EXTRA-1',
      'item_name': 'Extra item',
      'qty': 0.01,
      'rate': 1000,
      'uom': 'MT',
      'total_amount': 10,
    },
  ],
  'advance': [
    {
      'name': 'ALLOC-1',
      'reference_name': 'PAY-1',
      'allocated_amount': 5,
      'advance_amount': 100,
      'remarks': 'Existing allocation',
    },
  ],
  'pop_cash_payment': [
    {
      'name': 'CASH-1',
      'payment_type': 'Cash',
      'payment_from': 'A1',
      'paid_amount': 12,
      'due_amount': 5,
      'bank_payment_amount': 7,
      'check_knlg': 1,
    },
  ],
};

class EditData extends fixtures.PurchaseData {
  Map<String, dynamic> current = record();
  Map<String, dynamic>? updated;
  int creates = 0;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> getPointOfPurchase(String name) async =>
      Map<String, dynamic>.from(current);
  @override
  Future<Map<String, dynamic>> updatePointOfPurchase(
    String name,
    Map<String, dynamic> fields,
  ) async {
    expect(name, 'POP/EDIT-1');
    updated = Map.of(fields);
    if (fail) throw const AppException('Update denied');
    current = {...current, ...fields};
    return current;
  }

  @override
  Future<Map<String, dynamic>> createPointOfPurchase(
    Map<String, dynamic> fields,
  ) async {
    creates++;
    throw StateError('Editing must never create a purchase');
  }
}

Finder textField(String label) =>
    find.byWidgetPredicate((w) => w is AppTextField && w.label == label);

void main() {
  testWidgets(
    'Update opens a prefilled form, retains children, and saves the existing record',
    (tester) async {
      final repository = EditData();
      final vm = PointOfPurchaseViewModel(repository);
      final router = GoRouter(
        initialLocation: '/details',
        routes: [
          GoRoute(
            path: '/details',
            builder: (_, _) =>
                const PointOfPurchaseDetailScreen(documentName: 'POP/EDIT-1'),
          ),
          GoRoute(
            path: '/create',
            name: RouteNames.createPointOfPurchase,
            builder: (_, state) => CreatePointOfPurchaseScreen(
              documentName: state.uri.queryParameters['documentName'],
              initialRecord: state.extra as Map<String, dynamic>?,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Save')),
        findsOneWidget,
      );
      expect(find.text('Submit purchase'), findsNothing);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Update purchase'), findsOneWidget);
      expect(
        tester.widget<AppTextField>(textField('Village')).controller!.text,
        'Original village',
      );
      expect(
        tester.widget<AppTextField>(textField('Rate/kg *')).controller!.text,
        '10',
      );
      final company = tester.widget<AppDropdown<String>>(
        find.byWidgetPredicate(
          (w) => w is AppDropdown<String> && w.label == 'Company *',
        ),
      );
      expect(
        company.value,
        'C2',
      ); // Retain original company, rather than default index zero.
      expect(find.text('Extra item'), findsOneWidget);
      expect(find.text('PAY-1'), findsOneWidget);
      expect(find.text('2026-11-04'), findsOneWidget);
      expect(find.textContaining('1:45'), findsOneWidget);
      await tester.ensureVisible(textField('Village'));
      await tester.enterText(textField('Village'), 'Updated village');
      await tester.ensureVisible(textField('Courier Name'));
      await tester.enterText(textField('Courier Name'), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repository.updated, isNotNull);
      final payload = repository.updated!;
      expect(repository.creates, 0);
      expect(payload['village'], 'Updated village');
      expect(payload['courier_name'], '');
      expect(payload['company'], 'C2');
      expect(payload.containsKey('supplier_advance_allocation'), isFalse);
      expect(payload['date'], '2026-11-04');
      expect(payload['time'], '13:45:00');
      expect(payload.containsKey('paid'), isFalse);
      expect(payload.containsKey('gst'), isFalse);
      expect(payload['modified'], record()['modified']);
      expect((payload['total_bag'] as List).first['name'], 'BAG-1');
      expect((payload['total_bag'] as List).first['custom_bag'], 'keep');
      expect((payload['supplier_pop_item'] as List), hasLength(2));
      expect((payload['supplier_pop_item'] as List).first['name'], 'ITEM-1');
      expect(
        (payload['supplier_pop_item'] as List).first['custom_item'],
        'keep',
      );
      expect(payload['advance'], record()['advance']);
      expect((payload['pop_cash_payment'] as List).single['name'], 'CASH-1');
      expect(
        (payload['pop_cash_payment'] as List).single['payment_from'],
        'A1',
      );
      expect(payload['total_amount'], 250);
      expect(payload['grand_total'], 250);
      expect(payload['ship_payment'], 3);
      expect(payload['total_deduction'], 3);
      expect(payload['tare15kgsbag'], 3);
      expect(payload['net_payable'], 242);
      expect(find.text('Purchase updated successfully'), findsOneWidget);
      expect(vm.selectedRecord?['village'], 'Updated village');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      vm.dispose();
    },
  );
  testWidgets(
    'edit deep link loads the record, Reset restores original values, and failures keep edits',
    (tester) async {
      final repository = EditData()..fail = true;
      final vm = PointOfPurchaseViewModel(repository);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CreatePointOfPurchaseScreen(documentName: 'POP/EDIT-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(textField('Village'));
      await tester.enterText(textField('Village'), 'Edited village');
      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppTextField>(textField('Village')).controller!.text,
        'Original village',
      );
      await tester.ensureVisible(textField('Village'));
      await tester.enterText(textField('Village'), 'Edited village');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Update denied'), findsWidgets);
      expect(
        tester.widget<AppTextField>(textField('Village')).controller!.text,
        'Edited village',
      );
      expect(repository.creates, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets(
    'draft header Save and Update fit a narrow phone with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = PointOfPurchaseViewModel(EditData());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const PointOfPurchaseDetailScreen(documentName: 'POP/EDIT-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  group('update API', () {
    late Dio dio;
    late PointOfPurchaseRepository repository;
    late List<RequestOptions> requests;
    var status = 0;
    var modified = 'original';
    setUp(() {
      status = 0;
      modified = 'original';
      requests = [];
      dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
      dio.httpClientAdapter = Adapter((r) {
        requests.add(r);
        return r.method == 'GET'
            ? response({
                'message': {
                  'name': 'POP/EDIT-1',
                  'docstatus': status,
                  'modified': modified,
                },
              })
            : response({
                'data': {
                  'name': 'POP/EDIT-1',
                  'docstatus': 0,
                  ...r.data as Map,
                },
              });
      });
      final api = ApiClient(DioClient(dio: dio));
      repository = PointOfPurchaseRepository(
        FrappeResourceApi(api),
        methods: FrappeMethodApi(api),
      );
    });
    tearDown(() => dio.close());
    test(
      'uses PUT on the original document and preserves explicit clears',
      () async {
        await repository.updatePointOfPurchase('POP/EDIT-1', {
          'modified': 'original',
          'courier_name': '',
          'docstatus': 1,
          'name': 'wrong',
          'doctype': 'wrong',
        });
        expect(requests, hasLength(2));
        expect(requests.last.method, 'PUT');
        expect(
          requests.last.path,
          '/api/resource/Supplier%20Point%20Of%20Purchase/POP%2FEDIT-1',
        );
        expect(requests.last.data['courier_name'], '');
        expect((requests.last.data as Map).containsKey('docstatus'), isFalse);
        expect((requests.last.data as Map).containsKey('name'), isFalse);
      },
    );
    test('rejects changed documents before issuing PUT', () async {
      modified = 'newer';
      await expectLater(
        repository.updatePointOfPurchase('POP/EDIT-1', {
          'modified': 'original',
        }),
        throwsA(isA<AppException>()),
      );
      expect(requests, hasLength(1));
    });
    test('rejects submitted records before issuing PUT', () async {
      status = 1;
      await expectLater(
        repository.updatePointOfPurchase('POP/EDIT-1', {}),
        throwsA(isA<AppException>()),
      );
      expect(requests, hasLength(1));
    });
  });
}
