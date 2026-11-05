import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'dio_client.dart';
import '../cache/cache_manager.dart';
import 'connectivity_service.dart';

class ApiClient {
  ApiClient(this._client, {this.cache, this.connectivity});
  final CacheManager? cache;
  final ConnectivityService? connectivity;
  final DioClient _client;
  Dio get dio => _client.dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async => cache == null
      ? _request('GET', path, queryParameters: queryParameters)
      : cache!.read(
          path,
          queryParameters,
          () => _request('GET', path, queryParameters: queryParameters),
        );
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async =>
      _request('POST', path, data: data, queryParameters: queryParameters);
  Future<dynamic> put(String path, {dynamic data}) async =>
      _request('PUT', path, data: data);
  Future<dynamic> patch(String path, {dynamic data}) async =>
      _request('PATCH', path, data: data);
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async =>
      _request('DELETE', path, data: data, queryParameters: queryParameters);

  Future<dynamic> _request(
    String method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (dio.options.baseUrl.isEmpty) {
      throw const AppException(
        'Server URL is missing. Build with --dart-define=FRAPPE_BASE_URL=https://your-server.',
      );
    }
    if (method != 'GET' &&
        connectivity?.offline == true &&
        !path.endsWith('/login') &&
        !path.endsWith('/logout')) {
      throw const AppException(
        'Internet access is required to save changes. Please reconnect and try again.',
      );
    }
    final sessionGeneration = cache?.sessionGeneration;
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      if (sessionGeneration != cache?.sessionGeneration) {
        throw const AppException('The account changed. Please reload.');
      }
      connectivity?.success();
      final body = response.data;
      if (body is Map &&
          (body['exception'] != null || body['exc_type'] != null)) {
        connectivity?.reportRefreshFailure();
        throw const AppException('The server could not complete this request.');
      }
      if (method != 'GET' &&
          path.startsWith('/api/resource/') &&
          (method == 'DELETE' || (body is Map && body['data'] is Map))) {
        await cache?.invalidate(path);
      }
      return body;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      connectivity?.failure(error);
      if (error.error is AppException) throw error.error as AppException;
      throw const AppException(
        'Unable to reach the server. Check your connection.',
      );
    } catch (_) {
      throw const AppException('The server returned an invalid response.');
    }
  }
}
