import '../../config/constants/api_endpoints.dart';
import '../errors/app_exception.dart';
import 'api_client.dart';

class FrappeMethodApi {
  FrappeMethodApi(this._client);
  final ApiClient _client;
  Future<dynamic> callGetMethod(
    String methodPath, {
    Map<String, dynamic>? params,
    bool preserveResponse = false,
  }) async => _unwrap(
    await _client.get(_path(methodPath), queryParameters: params),
    preserveResponse,
  );
  Future<dynamic> callPostMethod(
    String methodPath, {
    Map<String, dynamic>? data,
    bool preserveResponse = false,
  }) async => _unwrap(
    await _client.post(_path(methodPath), data: data),
    preserveResponse,
  );
  Future<dynamic> callPutMethod(
    String methodPath, {
    Map<String, dynamic>? data,
    bool preserveResponse = false,
  }) async => _unwrap(
    await _client.put(_path(methodPath), data: data),
    preserveResponse,
  );
  Future<dynamic> callDeleteMethod(
    String methodPath, {
    Map<String, dynamic>? data,
    bool preserveResponse = false,
  }) async => _unwrap(
    await _client.delete(_path(methodPath), data: data),
    preserveResponse,
  );

  static String _path(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        normalized.contains('..')) {
      throw const AppException('Invalid Frappe method path.');
    }
    return '${ApiEndpoints.method}/$normalized';
  }

  static dynamic _unwrap(dynamic body, bool preserve) {
    if (preserve) return body;
    if (body is Map && body.containsKey('message')) return body['message'];
    throw const AppException('The server returned an invalid method response.');
  }
}
