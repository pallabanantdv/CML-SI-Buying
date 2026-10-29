import '../../../core/network/frappe_method_api.dart';
import '../../../core/network/frappe_resource_api.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/models/user_model.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  DashboardRepository(this._resources, this._methods);
  final FrappeResourceApi _resources;
  final FrappeMethodApi _methods;

  Future<DashboardModel> load() async {
    final user = UserModel.fromValue(
      await _methods.callGetMethod('frappe.auth.get_logged_user'),
    );
    try {
      final customers = await _resources.getDocList(
        'Customer',
        fields: ['name', 'customer_name'],
        limitPageLength: 10,
      );
      return DashboardModel(
        userName: user.fullName ?? user.id,
        customerCount: customers.length,
      );
    } on AppException catch (error) {
      return DashboardModel(
        userName: user.fullName ?? user.id,
        customerCount: null,
        customerError: error.message,
      );
    }
  }
}
