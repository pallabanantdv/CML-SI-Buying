import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/config/theme/app_theme.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_method_api.dart';
import 'package:cml_si_buying/features/dashboard/models/dashboard_data.dart';
import 'package:cml_si_buying/features/dashboard/repositories/api_dashboard_repository.dart';
import 'package:cml_si_buying/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:cml_si_buying/features/dashboard/widgets/dashboard_purchase_chart.dart';

Map<String, dynamic> summary() => {
  'from_date': '2025-01-04',
  'to_date': '2026-10-26',
  'currency': 'SBD',
  'total_purchase_value': 53503768.99,
  'total_transactions': 5040,
  'fully_paid': {'count': 5028},
  'fully_unpaid': {'count': 7},
  'partly_paid': {'count': 5},
  'items': [
    {
      'item_code': null,
      'item_name': 'SINPF',
      'qty': 1,
      'amount': 19483.74,
      'uom': 'Nos',
    },
    {
      'item_code': 'RAW-002',
      'item_name': 'RAW COPRA',
      'qty': 3624.377,
      'amount': 24062205.36,
      'uom': 'MT',
    },
    {
      'item_code': 'RAW-001',
      'item_name': 'RAW-001 - COCOA BEAN',
      'qty': 1064.873,
      'amount': 24152354.58,
      'uom': 'MT',
    },
  ],
  'trends': {
    'weekly': [
      {
        'period_start': '2026-10-19',
        'label': '19 Oct - 25 Oct 2026',
        'count': 12,
        'daily_counts': [
          {'short_day': 'Mon', 'count': 12},
          {'short_day': 'Tue', 'count': 0},
        ],
      },
      {
        'period_start': '2026-10-26',
        'label': '26 Oct - 01 Nov 2026',
        'count': 23,
        'daily_counts': [
          {'short_day': 'Mon', 'count': 23},
          {'short_day': 'Tue', 'count': 0},
        ],
      },
    ],
    'monthly': [
      {'label': 'Oct 2026', 'count': 665},
    ],
    'yearly': [
      {'label': '2025', 'count': 0},
    ],
  },
};

class SummaryMethods extends FrappeMethodApi {
  SummaryMethods() : super(ApiClient(DioClient(dio: Dio())));
  String? path;
  Map<String, dynamic>? query;
  @override
  Future<dynamic> callGetMethod(
    String methodPath, {
    Map<String, dynamic>? params,
    bool preserveResponse = false,
  }) async {
    if (methodPath.endsWith('get_revenue_from_pnl')) {
      return {
        'currency': 'SBD',
        'from_date': params?['from_date'],
        'to_date': params?['to_date'],
        'total_revenue': 24446858.82,
        'revenue_trends': {
          'quarterly': [
            {'label': 'Q2 2026', 'amount': 14563445.07},
            {'label': 'Q3 2026', 'amount': 9883413.75},
            {'label': 'Q4 2026', 'amount': 0},
          ],
        },
      };
    }
    path = methodPath;
    query = params;
    return summary();
  }
}

void main() {
  test('API summary uses invoice totals rather than treating item rows as transactions', () {
    final data = DashboardData.fromInvoiceSummary(summary());
    expect(data.isDemo, false);
    expect(data.summary.totalValue, 53503768.99);
    expect(data.summary.transactionCount, 5040);
    expect(data.products.length, 2);
    expect(data.products.map((product) => product.name), [
      'COCOA BEAN',
      'RAW COPRA',
    ]);
    expect(data.quantityFor(data.products.first.id), 1064.873);
    expect(data.amountFor(data.products.first.id), 24152354.58);
    expect(data.quantityFor(data.products.last.id), 3624.377);
    expect(data.amountFor(data.products.last.id), 24062205.36);
    expect(data.invoiceSummary!.paidCount, 5028);
    expect(data.invoiceSummary!.unpaidCount, 7);
    expect(data.invoiceSummary!.partlyPaidCount, 5);
  });

  test('loads the supplied endpoint and reloads with selected dates', () async {
    final methods = SummaryMethods();
    final vm = DashboardViewModel(ApiDashboardRepository(methods));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final previousYear = today.year - 1;
    final lastDay = DateTime(previousYear, today.month + 1, 0).day;
    final from = DateTime(
      previousYear,
      today.month,
      today.day > lastDay ? lastDay : today.day,
    );
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final defaultQuery = {'from_date': date(from), 'to_date': date(today)};
    await vm.ensureLoaded();
    expect(methods.path, 'erpnext.app_api.get_purchase_invoice_summary');
    expect(methods.query, defaultQuery);
    expect(vm.isEmpty, false);
    expect(vm.data!.revenue!.total, 24446858.82);
    expect(vm.data!.revenue!.quarters.last, ('Q4 2026', 0.0));
    await vm.setDateRange(DateTime(2026, 10, 19), DateTime(2026, 10, 25));
    expect(methods.query, {'from_date': '2026-10-19', 'to_date': '2026-10-25'});
    await vm.refresh();
    expect(methods.query!['from_date'], '2026-10-19');
    await vm.setDateRange(null, null);
    expect(methods.query, defaultQuery);
    vm.dispose();
  });

  testWidgets('week labels select daily counts and zero series render safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DashboardPurchaseChart(
            summary: DashboardData.fromInvoiceSummary(summary()).invoiceSummary,
          ),
        ),
      ),
    );
    expect(find.text('665 transactions'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Week'));
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Mon: 23 transactions\nAmount: SBD 0.00'),
      findsOneWidget,
    );
    await tester.tap(find.text('26 Oct - 01 Nov 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('19 Oct - 25 Oct 2026').last);
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Mon: 12 transactions\nAmount: SBD 0.00'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Year'));
    await tester.pumpAndSettle();
    expect(find.text('0 transactions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
