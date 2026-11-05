/// One purchase item is derived from all bag weights and the price per kg.
class CalculatedPurchaseItem {
  const CalculatedPurchaseItem({
    required this.itemCode,
    required this.itemName,
    required this.weightKg,
    required this.ratePerKg,
  });
  final String itemCode;
  final String itemName;
  final double weightKg;
  final double ratePerKg;
  double get quantityMt => weightKg / 1000;
  double get ratePerMt => ratePerKg * 1000;
  double get totalAmount => weightKg * ratePerKg;
  Map<String, dynamic> toJson() => {
    'item_code': itemCode,
    'item_name': itemName,
    'qty': quantityMt,
    'uom': 'MT',
    'rate': ratePerMt,
    'total_amount': totalAmount,
  };

  static const productItemNames = {'copra': 'RAW COPRA', 'cocoa': 'COCOA BEAN'};

  static String? itemNameForProduct(String? product) =>
      productItemNames[product?.trim().toLowerCase()];

  /// Product-to-item names are fixed for this organization. The item code still
  /// comes from the matching ERP record, so other copra/cocoa items are excluded.
  static Map<String, dynamic>? matchProduct(
    List<Map<String, dynamic>> options,
    String? product,
  ) {
    final target = itemNameForProduct(product);
    if (target == null) return null;
    String normalized(Object? value) => (value?.toString() ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toUpperCase();
    final name = normalized(target);
    final matches = options.where((item) {
      final code = normalized(item['value']);
      if (code.isEmpty) return false;
      final title = normalized(item['title']);
      return title == name || code == name || title == '$code - $name';
    }).toList();
    return matches.length == 1 ? matches.single : null;
  }
}
