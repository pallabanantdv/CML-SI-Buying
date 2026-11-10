import 'dart:convert';
import 'dart:typed_data';

import '../../../core/cache/cache_manager.dart';
import '../../../config/constants/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/frappe_method_api.dart';
import '../models/supplier_advance.dart';
import '../../../core/network/frappe_resource_api.dart';
import '../models/point_of_purchase_model.dart';

class PointOfPurchaseRepository {
  PointOfPurchaseRepository(this._resourceApi, {this.methods});

  final FrappeMethodApi? methods;

  static const _doctype = 'Supplier Point Of Purchase';
  final FrappeResourceApi _resourceApi;
  CacheManager? get cache => _resourceApi.cache;
  Uri get printServerUri => _resourceApi.serverUri;
  Future<Map<String, String>> printCookies() => _resourceApi.printCookies();
  Future<String> getInvoicePrintHtml(String invoice) => _resourceApi
      .getPrintHtml('Purchase Invoice', invoice, 'PI', language: 'en');
  Future<Uint8List> getInvoicePrintPdf(String invoice) => _resourceApi
      .getPrintPdf('Purchase Invoice', invoice, 'PI', language: 'en');

  Future<Uint8List> getPopPrintPdf(String name) =>
      _resourceApi.getPrintPdf(_doctype, name, 'POP TEMPLATE', language: 'en');

  static const warehouseAccountFields = [
    'cash_account',
    'bank_account',
    'inventory_account',
    'supplier_payable_account',
    'othershipping_account',
    'advance_receivable_account',
  ];

  Future<Map<String, String?>> getWarehouseAccounts(String warehouse) async {
    final methodApi = methods;
    if (methodApi == null) {
      throw const AppException('Warehouse account service is not configured.');
    }
    final response = await methodApi.callGetMethod(
      'frappe.client.get_list',
      params: {
        'doctype': 'Warehouse wise Account Setting',
        'filters': jsonEncode({'collection_location': warehouse}),
        'fields': jsonEncode(warehouseAccountFields),
        'limit_page_length': 1,
      },
    );
    if (response is! List ||
        response.length > 1 ||
        (response.isNotEmpty && response.first is! Map)) {
      throw const AppException(
        'The server returned invalid warehouse accounts.',
      );
    }
    final row = response.isEmpty ? <String, dynamic>{} : response.first as Map;
    return {
      for (final field in warehouseAccountFields) field: row[field]?.toString(),
    };
  }

  Future<List<SupplierAdvance>> getSupplierAdvances(String supplier) async {
    final methodApi = methods;
    if (methodApi == null) {
      throw const AppException('Supplier advance service is not configured.');
    }
    final response = await methodApi.callGetMethod(
      ApiEndpoints.supplierAdvance,
      params: {'supplier': supplier},
    );
    if (response is! List || response.any((row) => row is! Map)) {
      throw const AppException(
        'The server returned an invalid supplier advance list.',
      );
    }
    return response
        .map(
          (row) =>
              SupplierAdvance.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getSupplierById(String id) =>
      _resourceApi.getDoc('Supplier', id);

  Future<List<PointOfPurchaseModel>> getPointOfPurchases() async {
    final records = await _resourceApi.getDocList(
      _doctype,
      fields: PointOfPurchaseModel.listFields,
      orderBy: 'pop_datetime desc',
      limitPageLength: 50,
    );
    return records.map(PointOfPurchaseModel.fromJson).toList(growable: false);
  }

  Future<List<PointOfPurchaseModel>> getPurchasesForSupplier(
    String supplier,
  ) async {
    final rows = await _resourceApi.getDocList(
      _doctype,
      fields: PointOfPurchaseModel.listFields,
      filters: [
        ['supplier_name', '=', supplier],
      ],
      orderBy: 'pop_datetime desc',
      limitPageLength: 50,
    );
    return rows.map(PointOfPurchaseModel.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> searchSuppliers(String query) async =>
      _toOptions(
        await _resourceApi.getDocList(
          'Supplier',
          fields: [
            'name',
            'supplier_name',
            'supplier_type',
            'village',
            'province',
            'custom_island',
            'custom_contact_number',
            'mobile_no',
          ],
          filters: [
            ['disabled', '=', 0],
          ],
          orFilters: query.trim().isEmpty
              ? null
              : [
                  ['name', 'like', '%${query.trim()}%'],
                  ['supplier_name', 'like', '%${query.trim()}%'],
                ],
          orderBy: 'supplier_name asc',
          limitPageLength: 100,
        ),
        titleField: 'supplier_name',
        extraFields: const [
          'supplier_type',
          'village',
          'province',
          'custom_island',
          'custom_contact_number',
          'mobile_no',
        ],
      );

  Future<Map<String, dynamic>> getPointOfPurchase(String documentName) =>
      _resourceApi.getDoc(_doctype, documentName);

  /// Run Frappe's submit lifecycle, including server validations and permissions.
  Future<Map<String, dynamic>> submitPointOfPurchase(
    String documentName,
  ) async {
    final methodApi = methods;
    if (methodApi == null) {
      throw const AppException(
        'Purchase submission service is not configured.',
      );
    }
    if (cache?.connectivity.offline == true) {
      throw const AppException(
        'Internet access is required to submit a purchase.',
      );
    }
    final generation = cache?.sessionGeneration;
    // Read the current document from the server, bypassing the response cache.
    final current = await methodApi.callGetMethod(
      'frappe.client.get',
      params: {'doctype': _doctype, 'name': documentName},
    );
    if (current is! Map ||
        current['name'] != documentName ||
        int.tryParse('${current['docstatus']}') != 0) {
      throw const AppException(
        'Only draft purchases can be submitted. Refresh this record and try again.',
      );
    }
    final response = await methodApi.callPostMethod(
      'frappe.client.submit',
      data: {
        'doc': jsonEncode({...current, 'doctype': _doctype}),
      },
    );
    if (response is! Map ||
        response['name'] != documentName ||
        int.tryParse('${response['docstatus']}') != 1) {
      throw const AppException(
        'Submission could not be confirmed. Refresh the record to check its status.',
      );
    }
    if (generation != cache?.sessionGeneration) {
      throw const AppException('The account changed. Please reload.');
    }
    final submitted = Map<String, dynamic>.from(response);
    final path =
        '/api/resource/${Uri.encodeComponent(_doctype)}/${Uri.encodeComponent(documentName)}';
    await cache?.invalidate(path);
    if (generation != cache?.sessionGeneration) {
      throw const AppException('The account changed. Please reload.');
    }
    // Persist the actual server-confirmed document in its normal GET cache.
    await cache?.read(path, null, () async => {'data': submitted});
    return submitted;
  }

  Future<Map<String, dynamic>> updatePointOfPurchase(
    String documentName,
    Map<String, dynamic> fields,
  ) async {
    final methodApi = methods;
    if (methodApi == null) {
      throw const AppException('Purchase update service is not configured.');
    }
    if (cache?.connectivity.offline == true) {
      throw const AppException(
        'Internet access is required to update a purchase.',
      );
    }
    final generation = cache?.sessionGeneration;
    final current = await methodApi.callGetMethod(
      'frappe.client.get',
      params: {'doctype': _doctype, 'name': documentName},
    );
    if (current is! Map ||
        current['name'] != documentName ||
        int.tryParse('${current['docstatus']}') != 0) {
      throw const AppException(
        'Only draft purchases can be updated. Refresh this record.',
      );
    }
    if (fields['modified'] != null &&
        current['modified'] != fields['modified']) {
      throw const AppException(
        'This purchase has changed on the server. Reopen it before updating.',
      );
    }
    final payload = Map<String, dynamic>.from(fields)
      ..remove('name')
      ..remove('doctype')
      ..remove('docstatus')
      ..remove('naming_series');
    if (generation != cache?.sessionGeneration) {
      throw const AppException('The account changed. Please reload.');
    }
    final updated = await _resourceApi.updateDoc(
      _doctype,
      documentName,
      payload,
    );
    if (updated['name'] != documentName ||
        int.tryParse('${updated['docstatus']}') != 0) {
      throw const AppException(
        'The update could not be confirmed. Refresh the purchase to check its status.',
      );
    }
    if (generation != cache?.sessionGeneration) {
      throw const AppException('The account changed. Please reload.');
    }
    final path =
        '/api/resource/${Uri.encodeComponent(_doctype)}/${Uri.encodeComponent(documentName)}';
    await cache?.read(path, null, () async => {'data': updated});
    return updated;
  }

  Future<List<Map<String, dynamic>>> getSupplierOptions() async => _toOptions(
    await _resourceApi.getDocList(
      'Supplier',
      fields: const [
        'name',
        'supplier_name',
        'supplier_type',
        'village',
        'province',
        'custom_island',
        'custom_contact_number',
        'mobile_no',
      ],
      orderBy: 'supplier_name asc',
      limitPageLength: 200,
    ),
    titleField: 'supplier_name',
    extraFields: const [
      'supplier_type',
      'village',
      'province',
      'custom_island',
      'custom_contact_number',
      'mobile_no',
    ],
  );

  Future<List<Map<String, dynamic>>> getCollectionLocationOptions() async =>
      _toOptions(
        await _resourceApi.getDocList(
          'Warehouse',
          fields: const ['name'],
          filters: const [
            [
              'warehouse_type',
              'in',
              ['Cocoa Shed', 'Copra Shed'],
            ],
          ],
          orderBy: 'name asc',
          limitPageLength: 300,
        ),
        titleField: 'name',
      );

  Future<List<Map<String, dynamic>>> getItemOptions() async => _toOptions(
    await _resourceApi.getDocList(
      'Item',
      fields: const ['name', 'item_name', 'stock_uom'],
      orderBy: 'item_name asc',
      limitPageLength: 300,
    ),
    titleField: 'item_name',
    extraFields: const ['stock_uom'],
  );

  Future<List<Map<String, dynamic>>> getJournalEntryOptions() async =>
      _toOptions(
        await _resourceApi.getDocList(
          'Journal Entry',
          fields: const ['name', 'posting_date'],
          orderBy: 'posting_date desc',
          limitPageLength: 200,
        ),
        titleField: 'posting_date',
      );

  Future<List<Map<String, dynamic>>> getLinkOptions(
    String doctype, {
    List<String> fields = const ['name'],
    String titleField = 'name',
  }) async => _toOptions(
    await _resourceApi.getDocList(
      doctype,
      fields: fields,
      orderBy: '$titleField asc',
      limitPageLength: 300,
    ),
    titleField: titleField,
    extraFields: fields.where((field) => field != 'name').toList(),
  );

  Future<Map<String, dynamic>> createPointOfPurchase(
    Map<String, dynamic> fields,
  ) => _resourceApi.createDoc(_doctype, fields);

  static List<Map<String, dynamic>> _toOptions(
    List<Map<String, dynamic>> records, {
    required String titleField,
    List<String> extraFields = const [],
  }) => records
      .map((record) {
        final value = record['name']?.toString().trim() ?? '';
        if (value.isEmpty) return null;
        final title = record[titleField]?.toString().trim() ?? '';
        return <String, dynamic>{
          'value': value,
          'title': title.isEmpty ? value : title,
          'label': title.isEmpty || title == value ? value : '$value - $title',
          for (final field in extraFields) field: record[field],
        };
      })
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}
