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

  Future<List<Map<String, dynamic>>> getSupplierOptions() async =>
      _toOptions(
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
