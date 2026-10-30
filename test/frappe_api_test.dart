import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_method_api.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';

void main() {
  late Dio dio;
  late FrappeResourceApi resources;
  late FrappeMethodApi methods;
  late RequestOptions? captured;

  setUp(() {
    captured = null;
    dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
    dio.httpClientAdapter = _Adapter((request) {
      captured = request;
      if (request.path.endsWith('/fail')) {
        return {
          '_server_messages': jsonEncode([
            jsonEncode({'message': 'Quantity must be positive.'}),
          ]),
        };
      }
      if (request.path.contains('/api/method/')) {
        return {
          'message': ['ok', 2],
        };
      }
      if (request.path.endsWith('/api/resource/Sales%20Order')) {
        return {
          'data': [
            {'name': 'SO-1'},
          ],
        };
      }
      return {
        'data': {'name': 'A/B'},
      };
    });
    final client = ApiClient(DioClient(dio: dio));
    resources = FrappeResourceApi(client);
    methods = FrappeMethodApi(client);
  });

  test(
    'resource list encodes DocType and serializes filters and fields',
    () async {
      final result = await resources.getDocList(
        'Sales Order',
        fields: ['name'],
        filters: [
          ['status', '=', 'Open'],
        ],
        limitPageLength: 15,
      );
      expect(result.single['name'], 'SO-1');
      expect(captured!.path, '/api/resource/Sales%20Order');
      expect(captured!.queryParameters['fields'], '["name"]');
      expect(captured!.queryParameters['filters'], '[["status","=","Open"]]');
      expect(captured!.queryParameters['limit_page_length'], 15);
    },
  );

  test('document names are encoded as one URL segment', () async {
    final result = await resources.getDoc('Sales Order', 'A/B');
    expect(result['name'], 'A/B');
    expect(captured!.path, '/api/resource/Sales%20Order/A%2FB');
  });

  test(
    'method call keeps the dotted path and unwraps message values',
    () async {
      final value = await methods.callGetMethod('frappe.auth.get_logged_user');
      expect(value, ['ok', 2]);
      expect(captured!.path, '/api/method/frappe.auth.get_logged_user');
    },
  );

  test('method can return full response envelope', () async {
    final value = await methods.callGetMethod(
      'frappe.auth.get_logged_user',
      preserveResponse: true,
    );
    expect(value, {
      'message': ['ok', 2],
    });
  });

  test('Frappe validation errors become safe typed exceptions', () async {
    await expectLater(
      ApiClient(DioClient(dio: dio)).get('/fail'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'Quantity must be positive.',
        ),
      ),
    );
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final dynamic Function(RequestOptions request) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Iterable<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = respond(options);
    return ResponseBody.fromString(
      jsonEncode(data),
      options.path.endsWith('/fail') ? 417 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
