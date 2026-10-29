class DashboardModel {
  const DashboardModel({required this.userName, required this.customerCount, this.customerError});
  final String userName;
  final int? customerCount;
  final String? customerError;
}
