import '../models/dashboard_data.dart';
import '../models/dashboard_product_model.dart';
import '../models/dashboard_purchase_model.dart';
import 'dashboard_repository.dart';

/// The only source of demo values. Replace this implementation in DI for APIs.
class StaticDashboardRepository implements DashboardRepository {
  const StaticDashboardRepository();
  @override
  Future<DashboardData> getDashboardData() async => DashboardData(
    periodLabel: '1–8 November 2026',
    currencySymbol: r'$',
    isDemo: true,
    products: const [
      DashboardProductModel(id: 'a', name: 'Product A', unit: 'kg'),
      DashboardProductModel(id: 'b', name: 'Product B', unit: 'kg'),
    ],
    purchases: [
      for (final row in const [
        (1, 'a', 'Sample supplier North', 40.0, 5000.0),
        (2, 'b', 'Sample supplier West', 25.0, 3000.0),
        (3, 'a', 'Sample supplier North', 30.0, 3500.0),
        (4, 'b', 'Sample supplier East', 20.0, 2500.0),
        (5, 'a', 'Sample supplier West', 20.0, 2500.0),
        (6, 'b', 'Sample supplier East', 15.0, 2000.0),
        (7, 'a', 'Sample supplier North', 30.0, 3500.0),
        (8, 'b', 'Sample supplier West', 20.0, 2500.0),
      ])
        DashboardPurchaseModel(
          number: 'DEMO-POP-00${row.$1}',
          productId: row.$2,
          supplierName: row.$3,
          date: DateTime(2026, 11, row.$1),
          quantity: row.$4,
          amount: row.$5,
          status: row.$1 > 6
              ? DashboardPurchaseStatus.draft
              : DashboardPurchaseStatus.submitted,
        ),
    ],
  );
}
