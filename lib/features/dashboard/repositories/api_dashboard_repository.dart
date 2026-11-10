import '../../../core/errors/app_exception.dart';
import '../../../core/network/frappe_method_api.dart';
import '../models/dashboard_data.dart';
import 'dashboard_repository.dart';

class ApiDashboardRepository implements DateFilteredDashboardRepository {
  ApiDashboardRepository(this.methods);
  final FrappeMethodApi methods;

  @override
  Future<DashboardData> getDashboardData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(today.year, today.month, today.day - 30);
    return getDashboardDataForRange(from, today);
  }

  @override
  Future<DashboardData> getDashboardDataForRange(
    DateTime from,
    DateTime to,
  ) async {
    final response = await methods.callGetMethod(
      'erpnext.app_api.get_purchase_invoice_summary',
      params: {'from_date': _date(from), 'to_date': _date(to)},
    );
    if (response is! Map ||
        response['total_transactions'] == null ||
        response['total_purchase_value'] == null) {
      throw const AppException(
        'The server returned an invalid purchase summary.',
      );
    }
    return DashboardData.fromInvoiceSummary(
      Map<String, dynamic>.from(response),
    );
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
