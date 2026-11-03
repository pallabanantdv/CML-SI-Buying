enum DashboardPurchaseStatus { draft, submitted }

class DashboardPurchaseModel {
  const DashboardPurchaseModel({
    required this.number,
    required this.productId,
    required this.supplierName,
    required this.date,
    required this.quantity,
    required this.amount,
    required this.status,
    this.documentName,
  });
  final String number;
  final String productId;
  final String supplierName;
  final DateTime date;
  final double quantity;
  final double amount;
  final DashboardPurchaseStatus status;

  /// Only real ERP documents may open the existing purchase-detail route.
  final String? documentName;
}
