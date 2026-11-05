import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/core/cache/cache_manager.dart';
import 'package:cml_si_buying/core/cache/cache_service.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/api_client.dart';
import 'package:cml_si_buying/core/network/connectivity_service.dart';
import 'package:cml_si_buying/core/network/dio_client.dart';
import 'package:cml_si_buying/core/network/frappe_method_api.dart';
import 'package:cml_si_buying/core/network/frappe_resource_api.dart';
import 'package:cml_si_buying/core/services/session_service.dart';
import 'package:cml_si_buying/core/storage/secure_storage_service.dart';
import 'package:cml_si_buying/features/auth/repositories/auth_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';
import 'package:cml_si_buying/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(dynamic body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = '/api/resource/Supplier';
  const secure = FlutterSecureStorage();
  late Dio dio;
  late CacheManager cache;
  late ConnectivityService network;
  late ApiClient api;
  late int calls;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    calls = 0;
    network = ConnectivityService();
    final store = CacheService(secure);
    await store.initialize();
    cache = CacheManager(store, network, 'https://erp.example');
    await cache.activate('alice');
    dio = Dio(BaseOptions(baseUrl: 'https://erp.example'));
    dio.httpClientAdapter = Adapter((request) {
      calls++;
      return response({
        'data': [
          {'name': 'SUP-1'},
        ],
      });
    });
    api = ApiClient(
      DioClient(dio: dio),
      cache: cache,
      connectivity: network,
    );
  });
  tearDown(() {
    dio.close(force: true);
    network.dispose();
  });
  AuthRepository auth() => AuthRepository(
    api,
    FrappeMethodApi(api),
    SessionService(SecureStorageService(secure)),
    CookieJar(),
    cache: cache,
  );

  test('offline mutations never reach transport or report success', () async {
    network.offline = true;
    for (final action in [
      () => api.post(path, data: {'name': 'new'}),
      () => api.put('$path/A', data: {'name': 'new'}),
      () => api.patch('$path/A', data: {'name': 'new'}),
      () => api.delete('$path/A'),
    ]) {
      await expectLater(action(), throwsA(isA<AppException>()));
    }
    expect(calls, 0);
    expect(cache.store.entries, isEmpty);
  });
  test('only successful resource mutations invalidate cached reads', () async {
    await api.get(path);
    dio.httpClientAdapter = Adapter(
      (_) => response({'exc_type': 'ValidationError'}, 417),
    );
    await expectLater(api.post(path, data: {}), throwsA(isA<AppException>()));
    expect(cache.store.entries, hasLength(1));
    dio.httpClientAdapter = Adapter(
      (_) => response({
        'data': {'name': 'new'},
      }),
    );
    await api.post(path, data: {});
    expect(cache.store.entries, isEmpty);
  });
  test('server errors are refresh failures, not offline status', () async {
    dio.httpClientAdapter = Adapter(
      (_) => response({'message': 'unavailable'}, 503),
    );
    await expectLater(api.get(path), throwsA(isA<AppException>()));
    expect(network.offline, isFalse);
    expect(network.refreshFailed, isTrue);
    expect(cache.store.entries, isEmpty);
  });
  test('timeouts set offline status while preserving saved content', () async {
    await api.get(path);
    final failed = Completer<void>();
    dio.httpClientAdapter = Adapter((request) {
      failed.complete();
      throw DioException(
        requestOptions: request,
        type: DioExceptionType.connectionTimeout,
      );
    });
    expect(await CacheManager.force(() => api.get(path)), {
      'data': [
        {'name': 'SUP-1'},
      ],
    });
    await failed.future;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(network.offline, isTrue);
    expect(cache.store.entries, hasLength(1));
  });
  test(
    'offline session restoration needs a previously authenticated session',
    () async {
      network.hasNetwork = false;
      network.offline = true;
      expect(await auth().restoreSession(), isFalse);
      await SecureStorageService(secure).setSessionActive(true);
      final repository = auth();
      expect(await repository.restoreSession(), isTrue);
      expect((await repository.currentUser()).id, 'alice');
      expect(calls, 0);
      await repository.logout();
      expect(await SecureStorageService(secure).hasSession(), isFalse);
      expect(cache.owner, isNull);
      expect(await cache.savedIdentity(), isNull);
    },
  );
  test(
    'online restored identity replaces old cache owner and is fetched once',
    () async {
      await api.get(path);
      await SecureStorageService(secure).setSessionActive(true);
      var identities = 0;
      dio.httpClientAdapter = Adapter((_) {
        identities++;
        return response({'message': 'bob'});
      });
      final repository = auth();
      expect(await repository.restoreSession(), isTrue);
      expect((await repository.currentUser()).id, 'bob');
      expect(cache.owner, 'bob');
      expect(identities, 1);
      network.hasNetwork = false;
      await expectLater(api.get(path), throwsA(isA<AppException>()));
    },
  );
  test(
    'denied background reads remove saved content and emit revocation',
    () async {
      await api.get(path);
      final event = cache.updates.first;
      dio.httpClientAdapter = Adapter(
        (_) => response({'message': 'Forbidden'}, 403),
      );
      await CacheManager.force(() => api.get(path));
      expect(await event, 'revoke:$path');
      expect(cache.store.entries, isEmpty);
      expect(network.offline, isFalse);
    },
  );
  test(
    'detail view model preserves visible data during refresh and failure',
    () async {
      final pending = Completer<ResponseBody>();
      var first = true;
      dio.httpClientAdapter = Adapter((_) {
        if (first) {
          first = false;
          return response({
            'data': {'name': 'POP-1'},
          });
        }
        return pending.future;
      });
      final vm = PointOfPurchaseViewModel(
        PointOfPurchaseRepository(FrappeResourceApi(api)),
      );
      await vm.loadPointOfPurchase('POP-1');
      final refreshing = vm.loadPointOfPurchase('POP-1');
      expect(vm.selectedRecord?['name'], 'POP-1');
      await refreshing;
      pending.complete(response({'message': 'unavailable'}, 503));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(vm.selectedRecord?['name'], 'POP-1');
      vm.resetSession();
      expect(vm.selectedRecord, isNull);
      vm.dispose();
    },
  );
  for (final status in [401, 403]) {
    test('server identity denial $status removes the saved session', () async {
      await api.get(path);
      await SecureStorageService(secure).setSessionActive(true);
      dio.httpClientAdapter = Adapter(
        (_) => response({'message': 'Denied'}, status),
      );
      await expectLater(auth().restoreSession(), throwsA(isA<AppException>()));
      expect(cache.owner, isNull);
      expect(cache.store.entries, isEmpty);
      expect(await SecureStorageService(secure).hasSession(), isFalse);
    });
  }
  test('Guest identity cannot restore a saved authenticated session', () async {
    await SecureStorageService(secure).setSessionActive(true);
    dio.httpClientAdapter = Adapter((_) => response({'message': 'Guest'}));
    await expectLater(auth().restoreSession(), throwsA(isA<AppException>()));
    expect(cache.owner, isNull);
    expect(await SecureStorageService(secure).hasSession(), isFalse);
  });
  test('malformed successful read envelopes are not cached', () async {
    dio.httpClientAdapter = Adapter((_) => response({'data': 'invalid list'}));
    await expectLater(api.get(path), throwsA(isA<AppException>()));
    expect(cache.store.entries, isEmpty);
    expect(network.refreshFailed, isTrue);
    expect(network.offline, isFalse);
  });
}
