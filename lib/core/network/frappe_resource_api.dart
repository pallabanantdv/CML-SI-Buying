import 'dart:convert';

import '../../config/constants/api_endpoints.dart';
import '../errors/app_exception.dart';
import 'api_client.dart';

class FrappeResourceApi {
  FrappeResourceApi(this._client);
  final ApiClient _client;

  Future<List<Map<String, dynamic>>> getDocList(
    String doctype, {
    List<String>? fields,
    List<dynamic>? filters,
    List<dynamic>? orFilters,
    String? orderBy,
    int? limitStart,
    int? limitPageLength,
  }) async {
    final query = <String, dynamic>{};
    if (fields != null) query['fields'] = jsonEncode(fields);
    if (filters != null) query['filters'] = jsonEncode(filters);
    if (orFilters != null) query['or_filters'] = jsonEncode(orFilters);
    if (orderBy != null) query['order_by'] = orderBy;
    if (limitStart != null) query['limit_start'] = limitStart;
    if (limitPageLength != null) query['limit_page_length'] = limitPageLength;
    final body = await _client.get(
      '${ApiEndpoints.resource}/${_segment(doctype)}',
      queryParameters: query,
    );
    final data = _data(body);
    if (data is! List) {
      throw const AppException('The server returned an invalid record list.');
    }
    return data.map((item) => _map(item)).toList(growable: false);
  }

  Future<Map<String, dynamic>> getDoc(
    String doctype,
    String documentName,
  ) async => _map(
    _data(
      await _client.get(
        '${ApiEndpoints.resource}/${_segment(doctype)}/${_segment(documentName)}',
      ),
    ),
  );
  Future<Map<String, dynamic>> createDoc(
    String doctype,
    Map<String, dynamic> data,
  ) async => _map(
    _data(
      await _client.post(
        '${ApiEndpoints.resource}/${_segment(doctype)}',
        data: data,
      ),
    ),
  );
  Future<Map<String, dynamic>> updateDoc(
    String doctype,
    String documentName,
    Map<String, dynamic> data,
  ) async => _map(
    _data(
      await _client.put(
        '${ApiEndpoints.resource}/${_segment(doctype)}/${_segment(documentName)}',
        data: data,
      ),
    ),
  );
  Future<void> deleteDoc(String doctype, String documentName) async {
    await _client.delete(
      '${ApiEndpoints.resource}/${_segment(doctype)}/${_segment(documentName)}',
    );
  }

  static String _segment(String value) => Uri.encodeComponent(value);
  static dynamic _data(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    throw const AppException('The server returned an invalid response format.');
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const AppException('The server returned an invalid document.');
  }
}
