import 'dashboard_product_model.dart';
import 'dashboard_purchase_model.dart';
import 'dashboard_summary_model.dart';
import 'purchase_invoice_summary.dart';

class DashboardData {
  DashboardData({
    required this.periodLabel,
    required this.currencySymbol,
    required this.isDemo,
    required List<DashboardProductModel> products,
    required List<DashboardPurchaseModel> purchases,
    this.invoiceSummary,
  }) : products = List.unmodifiable(products),
       purchases = List.unmodifiable(purchases);
  final String periodLabel;
  final String currencySymbol;
  final bool isDemo;
  final PurchaseInvoiceSummary? invoiceSummary;

  factory DashboardData.fromInvoiceSummary(Map<String, dynamic> json) {
    final summary = PurchaseInvoiceSummary.fromJson(json);
    return DashboardData(
      periodLabel: '${summary.fromDate} – ${summary.toDate}',
      currencySymbol: '${summary.currency} ',
      isDemo: false,
      invoiceSummary: summary,
      products: [
        for (final item in const [
          ('RAW-001', 'COCOA BEAN'),
          ('RAW-002', 'RAW COPRA'),
        ])
          for (var i = 0; i < summary.items.length; i++)
            if (summary.items[i]['item_code'] == item.$1 ||
                '${summary.items[i]['item_name']}'.trim().toUpperCase() ==
                    item.$2)
              DashboardProductModel(
                id: '$i',
                name: item.$2,
                unit: '${summary.items[i]['uom'] ?? ''}',
              ),
      ],
      purchases: [],
    );
  }
  final List<DashboardProductModel> products;
  final List<DashboardPurchaseModel> purchases;
  DashboardSummaryModel get summary => DashboardSummaryModel(
    totalValue:
        invoiceSummary?.totalValue ??
        purchases.fold(0, (sum, purchase) => sum + purchase.amount),
    transactionCount: invoiceSummary?.transactions ?? purchases.length,
    productCount: products.length,
    draftCount: purchases
        .where((p) => p.status == DashboardPurchaseStatus.draft)
        .length,
    submittedCount: purchases
        .where((p) => p.status == DashboardPurchaseStatus.submitted)
        .length,
  );
  double quantityFor(String id) => invoiceSummary != null
      ? summaryNumber(invoiceSummary!.items[int.parse(id)]['qty'])
      : purchases
            .where((p) => p.productId == id)
            .fold(0, (sum, p) => sum + p.quantity);
  double amountFor(String id) => invoiceSummary != null
      ? summaryNumber(invoiceSummary!.items[int.parse(id)]['amount'])
      : purchases
            .where((p) => p.productId == id)
            .fold(0, (sum, p) => sum + p.amount);
  String productName(String id) =>
      products.where((p) => p.id == id).firstOrNull?.name ?? id;
  List<DashboardPurchaseModel> get recentPurchases =>
      (purchases.toList()..sort((a, b) => b.date.compareTo(a.date)))
          .take(4)
          .toList(growable: false);
}
