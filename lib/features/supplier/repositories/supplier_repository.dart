import 'dart:typed_data';

import '../../../core/cache/cache_manager.dart';
import '../../../core/network/frappe_resource_api.dart';
import '../models/supplier_model.dart';
import 'supplier_payment_repository.dart';

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
  CacheManager? get cache => _resourceApi.cache;
  SupplierPaymentRepository get payments =>
      SupplierPaymentRepository(_resourceApi);

  Future<String> uploadSupplierImage(Uint8List bytes, String filename) =>
      _resourceApi.uploadImage(bytes, filename);

  Future<Uint8List> getSupplierCard(String supplierId) =>
      _resourceApi.getPrintPdf(_doctype, supplierId, 'Card front 2');

  Uri get printServerUri => _resourceApi.serverUri;
  Future<Map<String, String>> printCookies() => _resourceApi.printCookies();
  Future<String> getSupplierCardHtml(String supplierId) =>
      _resourceApi.getPrintHtml(_doctype, supplierId, 'Card front 2');

  Future<List<String>> getSupplierFieldOptions(String doctype) async {
    if (!const {
      'Village',
      'Island',
      'Supplier Group',
      'Province',
    }.contains(doctype)) {
      throw ArgumentError.value(doctype, 'doctype');
    }
    const pageSize = 200;
    final names = <String>{};
    for (var offset = 0; ; offset += pageSize) {
      final records = await _resourceApi.getDocList(
        doctype,
        fields: const ['name'],
        orderBy: 'name asc',
        limitStart: offset,
        limitPageLength: pageSize,
      );
      for (final record in records) {
        final name = record['name']?.toString().trim();
        if (name != null && name.isNotEmpty) names.add(name);
      }
      if (records.length < pageSize) break;
    }
    return names.toList()..sort();
  }

  Future<List<SupplierModel>> getSuppliers() async {
    final records = await _resourceApi.getDocList(
      _doctype,
      fields: _listFields,
      orderBy: 'modified desc',
      limitPageLength: 100,
    );
    return records.map(SupplierModel.fromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> getSupplier(String documentName) =>
      _resourceApi.getDoc(_doctype, documentName);

  Future<SupplierModel> createSupplier(Map<String, dynamic> fields) async =>
      SupplierModel.fromJson(await _resourceApi.createDoc(_doctype, fields));

  Future<SupplierModel> updateSupplier(
    String id,
    Map<String, dynamic> fields,
  ) async => SupplierModel.fromJson(
    await _resourceApi.updateDoc(_doctype, id, fields),
  );
}
