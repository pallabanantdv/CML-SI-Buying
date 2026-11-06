import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../errors/app_exception.dart';
import '../models/html_print_document.dart';
import 'dio_client.dart';
import '../cache/cache_manager.dart';
import 'connectivity_service.dart';

class ApiClient {
  ApiClient(this._client, {this.cache, this.connectivity});
  final CacheManager? cache;
  final ConnectivityService? connectivity;
  final DioClient _client;
  Dio get dio => _client.dio;

  Future<String> getHtml(String path, Map<String, dynamic> query) async {
    final body = await _request(
      'GET',
      path,
      queryParameters: query,
      responseType: ResponseType.plain,
    );
    return HtmlPrintDocument.extractHtml(body);
  }

  Uri get serverUri => Uri.parse(dio.options.baseUrl);

  Future<Map<String, String>> printCookies() async {
    final cookies = <String, String>{};
    for (final manager in dio.interceptors.whereType<CookieManager>()) {
      for (final cookie in await manager.cookieJar.loadForRequest(
        serverUri.resolve('/printview'),
      )) {
        cookies[cookie.name] = cookie.value;
      }
    }
    return cookies;
  }

  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final body = await post(
      '/api/method/upload_file',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'is_private': '0',
      }),
    );
    final message = body is Map ? body['message'] : null;
    final url = message is Map ? message['file_url'] : null;
    if (url is! String || url.trim().isEmpty) {
      throw const AppException('The image upload did not return a file URL.');
    }
    return url;
  }

  Future<Uint8List> getPdf(
    String path, {
    required Map<String, dynamic> queryParameters,
  }) async {
    final body = await _request(
      'GET',
      path,
      queryParameters: queryParameters,
      responseType: ResponseType.bytes,
    );
    if (body is! List<int> ||
        body.length < 5 ||
        String.fromCharCodes(body.take(5)) != '%PDF-') {
      throw const AppException('The server did not return a valid PDF card.');
    }
    return Uint8List.fromList(body);
  }

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
    ResponseType? responseType,
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
        options: Options(
          method: method,
          responseType: responseType,
          contentType: data is FormData ? 'multipart/form-data' : null,
        ),
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
