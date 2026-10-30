import '../../../core/network/frappe_resource_api.dart';
import '../models/supplier_model.dart';

class SupplierRepository {
  SupplierRepository(this._resourceApi);

  static const _doctype = 'Supplier';
  static const _listFields = [
    'name',
    'supplier_name',
    'supplier_group',
    'supplier_type',
    'country',
    'province',
    'custom_island',
    'village',
    'mobile_no',
    'custom_contact_number',
    'email_id',
    'custom_status',
    'disabled',
    'is_frozen',
    'on_hold',
  ];

  final FrappeResourceApi _resourceApi;

  Future<List<SupplierModel>> getSuppliers() async {
    final records = await _resourceApi.getDocList(
      _doctype,
      fields: _listFields,
      orderBy: 'modified desc',
      limitPageLength: 100,
    );
    return records.map(SupplierModel.fromJson).toList(growable: false);
  }

  Future<SupplierModel> createSupplier(Map<String, dynamic> fields) async =>
      SupplierModel.fromJson(await _resourceApi.createDoc(_doctype, fields));
}
