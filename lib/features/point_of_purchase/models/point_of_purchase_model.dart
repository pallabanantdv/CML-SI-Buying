class PointOfPurchaseModel {
  const PointOfPurchaseModel({
    required this.name,
    this.supplierName,
    this.supplierId,
    this.collectionLocation,
    this.productType,
    this.purchaseDateTime,
    this.supplierType,
    this.grossWeight,
    this.rate,
    this.paymentMode,
    this.grandTotal,
    this.netPayable,
    this.docStatus,
  });

  static const listFields = [
    'name',
    'supplier_name1',
    'supplier_name',
    'collection_location',
    'custom_product_type',
    'pop_datetime',
    'gross_weight',
    'grand_total',
    'net_payable',
    'docstatus',
  ];

  final String name;
  final String? supplierName;
  final String? supplierId;
  final String? collectionLocation;
  final String? productType;
  final String? purchaseDateTime;
  final String? supplierType;
  final double? grossWeight;
  final double? rate;
  final String? paymentMode;
  final double? grandTotal;
  final double? netPayable;
  final int? docStatus;

  factory PointOfPurchaseModel.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      if (value == null || value.toString().trim().isEmpty) return null;
      return value.toString();
    }

    double? number(String key) => double.tryParse(json[key]?.toString() ?? '');
    int? integer(String key) => int.tryParse(json[key]?.toString() ?? '');

    return PointOfPurchaseModel(
      name: text('name') ?? '',
      supplierName: text('supplier_name1') ?? text('supplier_name'),
      supplierId: text('supplier_name'),
      collectionLocation: text('collection_location'),
      productType: text('custom_product_type'),
      purchaseDateTime: text('pop_datetime'),
      supplierType: text('supplier_type'),
      grossWeight: number('gross_weight'),
      rate: number('rate'),
      paymentMode: text('mode_of_payment'),
      grandTotal: number('grand_total'),
      netPayable: number('net_payable'),
      docStatus: integer('docstatus'),
    );
  }
}
