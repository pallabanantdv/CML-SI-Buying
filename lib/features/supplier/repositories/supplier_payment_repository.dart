import 'dart:convert';

import '../../../config/constants/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/frappe_resource_api.dart';

class SupplierPaymentRepository {
  SupplierPaymentRepository(this.api);
  final FrappeResourceApi api;

  static const pageSize = 50;

  Future<Map<String, dynamic>> details(String name) async {
    final record = await api.getDoc('Payment Entry', name);
    if (record['name'] != name ||
        record['party_type'] != 'Supplier' ||
        record['payment_type'] != 'Pay') {
      throw const AppException('This supplier payment entry is unavailable.');
    }
    return record;
  }

  Future<List<Map<String, dynamic>>> entries({int offset = 0, int? status}) =>
      api.getDocList(
        'Payment Entry',
        fields: [
          'name',
          'posting_date',
          'company',
          'party',
          'party_name',
          'payment_type',
          'mode_of_payment',
          'paid_amount',
          'paid_from_account_currency',
          'docstatus',
        ],
        filters: [
          ['party_type', '=', 'Supplier'],
          // ['payment_type', '=', 'Pay'],
          if (status != null) ['docstatus', '=', status],
        ],
        orderBy: 'modified desc, name desc',
        limitStart: offset,
        limitPageLength: pageSize,
      );

  Future<Map<String, dynamic>> submit(String name) async {
    if (api.cache?.connectivity.offline == true) {
      throw const AppException(
        'Connect to the internet before submitting a payment entry.',
      );
    }
    final generation = api.cache?.sessionGeneration;
    final current = await api.methods.callGetMethod(
      'frappe.client.get',
      params: {'doctype': 'Payment Entry', 'name': name},
    );
    if (generation != api.cache?.sessionGeneration) {
      throw const AppException('The account changed. Please reload.');
    }
    if (current is! Map ||
        current['name'] != name ||
        current['party_type'] != 'Supplier' ||
        // current['payment_type'] != 'Pay' ||
        int.tryParse('${current['docstatus']}') != 0) {
      throw const AppException(
        'Only draft supplier payments can be submitted. Refresh the list to check its status.',
      );
    }
    final result = await api.methods.callPostMethod(
      'frappe.client.submit',
      data: {
        'doc': jsonEncode({...current, 'doctype': 'Payment Entry'}),
      },
    );
    if (generation != api.cache?.sessionGeneration) {
      throw const AppException('The account changed. Please reload.');
    }
    if (result is! Map ||
        result['name'] != name ||
        int.tryParse('${result['docstatus']}') != 1) {
      throw const AppException(
        'Submission could not be confirmed. Refresh the payment entry before trying again.',
      );
    }
    await api.cache?.invalidate(
      '/api/resource/Payment%20Entry/${Uri.encodeComponent(name)}',
    );
    await api.cache?.invalidate('/api/method/${ApiEndpoints.supplierAdvance}');
    if (generation != api.cache?.sessionGeneration) {
      throw const AppException('The account changed. Please reload.');
    }
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> companies() => api.getDocList(
    'Company',
    fields: ['name', 'default_currency'],
    limitPageLength: 100,
  );
  Future<List<Map<String, dynamic>>> suppliers({String query = ''}) =>
      api.getDocList(
        'Supplier',
        fields: ['name', 'supplier_name'],
        filters: [
          ['disabled', '=', 0],
        ],
        orFilters: query.trim().isEmpty
            ? null
            : [
                ['name', 'like', '%${query.trim()}%'],
                ['supplier_name', 'like', '%${query.trim()}%'],
              ],
        limitPageLength: 100,
      );
  Future<List<Map<String, dynamic>>> modes() => api.getDocList(
    'Mode of Payment',
    fields: ['name', 'type'],
    filters: [
      ['enabled', '=', 1],
    ],
    limitPageLength: 100,
  );
  Future<List<Map<String, dynamic>>> accounts(String company) => api.getDocList(
    'Account',
    fields: ['name', 'account_name', 'account_type', 'account_currency'],
    filters: [
      ['company', '=', company],
      ['is_group', '=', 0],
      ['disabled', '=', 0],
      [
        'account_type',
        'in',
        ['Bank', 'Cash', 'Payable', 'Receivable'],
      ],
    ],
    limitPageLength: 1000,
  );
  Future<List<Map<String, dynamic>>> invoices(
    String company,
    String supplier,
    String currency,
  ) => api.getDocList(
    'Purchase Invoice',
    fields: [
      'name',
      'outstanding_amount',
      'grand_total',
      'due_date',
      'currency',
      'credit_to',
      'conversion_rate',
    ],
    filters: [
      ['company', '=', company],
      ['supplier', '=', supplier],
      ['docstatus', '=', 1],
      ['outstanding_amount', '>', 0],
      ['currency', '=', currency],
    ],
    limitPageLength: 1000,
  );

  Future<String> create(Map<String, dynamic> fields) async {
    final result = await api.createDoc('Payment Entry', fields);
    final name = result['name'];
    if (name is! String ||
        name.isEmpty ||
        int.tryParse('${result['docstatus']}') != 0) {
      throw const AppException(
        'Payment save could not be confirmed. Check ERPNext before trying again.',
      );
    }
    return name;
  }
}
