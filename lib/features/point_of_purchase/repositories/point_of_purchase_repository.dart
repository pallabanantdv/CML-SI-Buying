import '../../../core/network/frappe_resource_api.dart';
import '../models/point_of_purchase_model.dart';

class PointOfPurchaseRepository {
  PointOfPurchaseRepository(this._resourceApi);

  static const _doctype = 'Supplier Point Of Purchase';
  final FrappeResourceApi _resourceApi;

  Future<List<PointOfPurchaseModel>> getPointOfPurchases() async {
    final records = await _resourceApi.getDocList(
      _doctype,
      fields: PointOfPurchaseModel.listFields,
      orderBy: 'pop_datetime desc',
      limitPageLength: 50,
    );
    return records.map(PointOfPurchaseModel.fromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> getPointOfPurchase(String documentName) =>
      _resourceApi.getDoc(_doctype, documentName);
}
