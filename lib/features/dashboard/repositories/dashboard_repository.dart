import '../models/dashboard_data.dart';

abstract interface class DashboardRepository {
  Future<DashboardData> getDashboardData();
}
