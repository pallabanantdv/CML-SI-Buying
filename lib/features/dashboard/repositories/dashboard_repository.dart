import '../models/dashboard_data.dart';

abstract interface class DashboardRepository {
  Future<DashboardData> getDashboardData();
}

abstract interface class DateFilteredDashboardRepository
    implements DashboardRepository {
  Future<DashboardData> getDashboardDataForRange(DateTime from, DateTime to);
}
