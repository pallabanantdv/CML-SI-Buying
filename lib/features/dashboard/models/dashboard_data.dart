import 'dashboard_product_model.dart';
import 'dashboard_purchase_model.dart';
import 'dashboard_summary_model.dart';

class DashboardData {
  DashboardData({
    required this.periodLabel,
    required this.currencySymbol,
    required this.isDemo,
    required List<DashboardProductModel> products,
    required List<DashboardPurchaseModel> purchases,
  }) : products = List.unmodifiable(products),
       purchases = List.unmodifiable(purchases);
  final String periodLabel;
  final String currencySymbol;
  final bool isDemo;
  final List<DashboardProductModel> products;
  final List<DashboardPurchaseModel> purchases;
  DashboardSummaryModel get summary => DashboardSummaryModel(
    totalValue: purchases.fold(0, (sum, purchase) => sum + purchase.amount),
    transactionCount: purchases.length,
    productCount: products.length,
    draftCount: purchases
        .where((p) => p.status == DashboardPurchaseStatus.draft)
        .length,
    submittedCount: purchases
        .where((p) => p.status == DashboardPurchaseStatus.submitted)
        .length,
  );
  double quantityFor(String id) => purchases
      .where((p) => p.productId == id)
      .fold(0, (sum, p) => sum + p.quantity);
  double amountFor(String id) => purchases
      .where((p) => p.productId == id)
      .fold(0, (sum, p) => sum + p.amount);
  String productName(String id) =>
      products.where((p) => p.id == id).firstOrNull?.name ?? id;
  List<DashboardPurchaseModel> get recentPurchases =>
      (purchases.toList()..sort((a, b) => b.date.compareTo(a.date)))
          .take(4)
          .toList(growable: false);
}
