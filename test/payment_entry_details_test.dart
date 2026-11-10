import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_payment_repository.dart';
import 'package:cml_si_buying/features/supplier/repositories/supplier_repository.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_viewmodel.dart';
import 'package:cml_si_buying/features/supplier/views/payment_entry_details.dart';

class PaymentApi extends FrappeResourceApi {
  PaymentApi() : super(ApiClient(DioClient(dio: Dio())));
  Completer<Map<String, dynamic>> response = Completer();
  int calls = 0;

  @override
  Future<Map<String, dynamic>> getDoc(String doctype, String name) {
    expect(doctype, 'Payment Entry');
    expect(name, 'ACC/PAY 1');
    calls++;
    return response.future;
  }
}

Map<String, dynamic> document() => {
  'name': 'ACC/PAY 1',
  'party_type': 'Supplier',
  'payment_type': 'Pay',
  'docstatus': 1,
  'party_name': 'Island supplier',
  'paid_amount': 120,
  'paid_from': 'Bank account',
  'references': [
    {'reference_name': 'PINV-42', 'allocated_amount': 120},
  ],
  'deductions': [
    {'account': 'Bank fees', 'amount': 2},
  ],
};

Future<void> mount(WidgetTester tester, PaymentApi api) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SupplierViewModel(SupplierRepository(api)),
      child: MaterialApp(
        theme: AppTheme.light,
        home: const PaymentEntryDetailsScreen(documentName: 'ACC/PAY 1'),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'payment values remain selectable after repeated section toggles',
    (tester) async {
      final api = PaymentApi();
      await mount(tester, api);
      api.response.complete(document());
      await tester.pumpAndSettle();

      for (var i = 0; i < 40; i++) {
        await tester.tap(find.text('Payment information'));
        // Also reverse the animation before it finishes on alternating taps.
        await tester.pump(Duration(milliseconds: i.isEven ? 40 : 300));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(find.text('Island supplier'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Island supplier'),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
      await tester.longPress(find.text('Island supplier'));
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loads full payment including references and deductions', (
    tester,
  ) async {
    final api = PaymentApi();
    await mount(tester, api);
    expect(api.calls, 1);
    api.response.complete(document());
    await tester.pumpAndSettle();
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Island supplier'), findsOneWidget);
    await tester.tap(find.text('Payment information'));
    await tester.pumpAndSettle();
    expect(find.text('Island supplier'), findsNothing);
    await tester.tap(find.text('Payment information'));
    await tester.pumpAndSettle();
    expect(find.text('Island supplier'), findsOneWidget);
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('PINV-42'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('PINV-42'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bank fees'),
      150,
      scrollable: scrollable,
    );
    expect(find.text('Bank fees'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed detail request can be retried', (tester) async {
    final api = PaymentApi();
    await mount(tester, api);
    api.response.completeError(const AppException('Payment unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Payment unavailable'), findsOneWidget);
    api.response = Completer();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    api.response.complete(document());
    await tester.pumpAndSettle();
    expect(api.calls, 2);
    expect(find.text('Island supplier'), findsOneWidget);
  });

  test('rejects a document outside supplier payments', () async {
    final api = PaymentApi();
    final result = SupplierPaymentRepository(api).details('ACC/PAY 1');
    api.response.complete({...document(), 'party_type': 'Customer'});
    await expectLater(result, throwsA(isA<AppException>()));
  });
}
