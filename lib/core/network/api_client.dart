import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'dio_client.dart';

class ApiClient {
  ApiClient(this._client);
  final DioClient _client;
  Dio get dio => _client.dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async => _request('GET', path, queryParameters: queryParameters);
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
    try {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      return response.data;
    } on DioException catch (error) {
      if (error.error is AppException) throw error.error as AppException;
      throw const AppException(
        'Unable to reach the server. Check your connection.',
      );
    } catch (_) {
      throw const AppException('The server returned an invalid response.');
    }
  }
}
