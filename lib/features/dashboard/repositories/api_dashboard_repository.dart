import '../../../core/errors/app_exception.dart';
import '../../../core/network/frappe_method_api.dart';
import '../models/dashboard_data.dart';
import '../models/revenue_summary.dart';
import 'dashboard_repository.dart';

class ApiDashboardRepository implements DateFilteredDashboardRepository {
  ApiDashboardRepository(this.methods);
  final FrappeMethodApi methods;

  @override
  Future<DashboardData> getDashboardData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final previousYear = today.year - 1;
    final lastDay = DateTime(previousYear, today.month + 1, 0).day;
    final from = DateTime(
      previousYear,
      today.month,
      today.day > lastDay ? lastDay : today.day,
    );
    return getDashboardDataForRange(from, today);
  }

  @override
  Future<DashboardData> getDashboardDataForRange(
    DateTime from,
    DateTime to,
  ) async {
    final params = {'from_date': _date(from), 'to_date': _date(to)};
    final results = await Future.wait<dynamic>([
      methods.callGetMethod(
        'erpnext.app_api.get_purchase_invoice_summary',
        params: params,
      ),
      _loadRevenue(params),
    ]);
    final response = results[0];
    if (response is! Map ||
        response['total_transactions'] == null ||
        response['total_purchase_value'] == null) {
      throw const AppException(
        'The server returned an invalid purchase summary.',
      );
    }
    return DashboardData.fromInvoiceSummary(
      Map<String, dynamic>.from(response),
      revenue: results[1] as RevenueSummary?,
    );
  }

  Future<RevenueSummary?> _loadRevenue(Map<String, dynamic> params) async {
    try {
      final response = await methods.callGetMethod(
        'erpnext.app_api.get_revenue_from_pnl',
        params: params,
      );
      if (response is! Map || response['total_revenue'] == null) return null;
      return RevenueSummary.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      // A revenue failure must not hide the purchase overview.
      return null;
    }
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
