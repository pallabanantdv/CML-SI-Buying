class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.totalValue,
    required this.transactionCount,
    required this.productCount,
    required this.draftCount,
    required this.submittedCount,
  });
  final double totalValue;
  final int transactionCount;
  final int productCount;
  final int draftCount;
  final int submittedCount;
}
