import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/core/cache/cache_entry.dart';
import 'package:cml_si_buying/core/cache/cache_keys.dart';
import 'package:cml_si_buying/core/cache/cache_manager.dart';
import 'package:cml_si_buying/core/cache/cache_policy.dart';
import 'package:cml_si_buying/core/cache/cache_service.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/core/network/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = '/api/resource/Supplier';
  const storage = FlutterSecureStorage();
  late CacheService store;
  late ConnectivityService network;
  late CacheManager cache;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    store = CacheService(storage);
    await store.initialize();
    network = ConnectivityService();
    cache = CacheManager(store, network, 'https://erp.example');
    await cache.activate('alice');
  });
  tearDown(() => network.dispose());
  Map<String, dynamic> body(String name) => {
    'data': [
      {'name': name},
    ],
  };

  test('canonical keys include server, user, endpoint, filters and page', () {
    String key(String user, Map<String, dynamic> query) =>
        CacheKeys.request('server', user, path, query);
    expect(
      key('a', {
        'page': 1,
        'filters': {'b': 2, 'a': 1},
      }),
      key('a', {
        'filters': {'a': 1, 'b': 2},
        'page': 1,
      }),
    );
    expect(key('a', {'page': 1}), isNot(key('a', {'page': 2})));
    expect(key('a', {}), isNot(key('b', {})));
    expect(
      CacheKeys.request('s1', 'a', path, {}),
      isNot(CacheKeys.request('s2', 'a', path, {})),
    );
    expect(
      CacheKeys.request('s1', 'a', '$path/A', {}),
      isNot(CacheKeys.request('s1', 'a', '$path/B', {})),
    );
    expect(CacheKeys.canonical([1, 2]), isNot(CacheKeys.canonical([2, 1])));
  });
  test('freshness boundaries retain expired entries', () async {
    await cache.read(path, null, () async => body('old'));
    final entry = store.entries.values.single;
    expect(
      entry.isFresh(entry.updatedAt.add(const Duration(minutes: 9))),
      isTrue,
    );
    expect(
      entry.isFresh(entry.updatedAt.add(const Duration(minutes: 10))),
      isFalse,
    );
    expect(store.entries, hasLength(1));
  });
  test(
    'successful reads persist through a new cache instance offline',
    () async {
      await cache.read(path, {'limit_start': 0}, () async => body('A'));
      final restarted = CacheService(storage);
      await restarted.initialize();
      final restored = CacheManager(restarted, network, 'https://erp.example');
      expect(await restored.savedIdentity(), 'alice');
      await restored.activate('alice');
      network.hasNetwork = false;
      expect(
        await restored.read(path, {
          'limit_start': 0,
        }, () => throw StateError('network called')),
        body('A'),
      );
    },
  );
  test('first offline visit gives a retryable friendly error', () async {
    network.hasNetwork = false;
    await expectLater(
      cache.read(path, null, () async => body('A')),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('Retry'),
        ),
      ),
    );
  });
  test(
    'cache displays before background refresh and emits changed endpoint',
    () async {
      await cache.read(path, null, () async => body('old'));
      final pending = Completer<dynamic>();
      final updated = cache.updates.first;
      final result = await CacheManager.force(
        () => cache.read(path, null, () => pending.future),
      );
      expect(result, body('old'));
      pending.complete(body('new'));
      expect(await updated, path);
      expect(store.entries.values.single.data, body('new'));
    },
  );
  test(
    'failed refresh preserves cache and consumes background failure',
    () async {
      await cache.read(path, null, () async => body('old'));
      expect(
        await CacheManager.force(
          () => cache.read(
            path,
            null,
            () async => throw const AppException('Timeout'),
          ),
        ),
        body('old'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.entries.values.single.data, body('old'));
    },
  );
  test('concurrent cold reads share one request', () async {
    var calls = 0;
    final pending = Completer<dynamic>();
    Future<dynamic> fetch() {
      calls++;
      return pending.future;
    }

    final a = cache.read(path, null, fetch);
    final b = cache.read(path, null, fetch);
    pending.complete(body('A'));
    expect(await a, await b);
    expect(calls, 1);
  });
  test('concurrent forced refreshes share one request', () async {
    await cache.read(path, null, () async => body('old'));
    var calls = 0;
    final pending = Completer<dynamic>();
    Future<dynamic> fetch() {
      calls++;
      return pending.future;
    }

    await Future.wait([
      CacheManager.force(() => cache.read(path, null, fetch)),
      CacheManager.force(() => cache.read(path, null, fetch)),
    ]);
    expect(calls, 1);
    final changed = cache.updates.first;
    pending.complete(body('new'));
    await changed;
  });
  test('mutation invalidates related lists and details only', () async {
    await cache.read(path, null, () async => body('A'));
    await cache.read(
      '$path/A',
      null,
      () async => {
        'data': {'name': 'A'},
      },
    );
    await cache.read('/api/resource/Item', null, () async => body('item'));
    await cache.invalidate('$path/A');
    expect(store.entries.values.map((e) => e.endpoint), ['/api/resource/Item']);
  });
  test('logout deletes data and late requests cannot restore it', () async {
    final pending = Completer<dynamic>();
    final oldRequest = cache.read(path, null, () => pending.future);
    final assertion = expectLater(oldRequest, throwsA(isA<AppException>()));
    await cache.clearSession();
    await cache.activate('bob');
    pending.complete(body('alice-private'));
    await assertion;
    expect(store.entries, isEmpty);
    network.hasNetwork = false;
    await expectLater(
      cache.read(path, null, () async => body('B')),
      throwsA(isA<AppException>()),
    );
  });
  test(
    'unknown endpoints, auth, writes and secrets are excluded by policy',
    () {
      expect(CachePolicy.forRequest('/api/method/login', null), isNull);
      expect(CachePolicy.forRequest('/api/method/unreviewed', null), isNull);
      expect(CachePolicy.forRequest('/api/resource/User/alice', null), isNull);
      for (final response in [
        {'exception': 'bad', 'data': []},
        {'exc_type': 'bad', 'message': []},
        {
          'data': {'api_secret': 'secret'},
        },
        {
          'data': [
            {
              'nested': {'access_token': 'secret'},
            },
          ],
        },
      ]) {
        expect(CachePolicy.safeResponse(response), isFalse);
      }
    },
  );
  test(
    'storage is bounded and corrupt or unknown versions are recoverable',
    () async {
      final bounded = CacheService(storage, maxEntries: 1);
      final manager = CacheManager(bounded, network, 'server');
      await manager.activate('alice');
      await manager.read(path, {'page': 1}, () async => body('A'));
      await manager.read(path, {'page': 2}, () async => body('B'));
      expect(bounded.entries, hasLength(1));
      final entry = bounded.entries.values.single.toJson();
      await storage.write(
        key: CacheService.storageKey,
        value: jsonEncode([
          {...entry, 'version': 99},
          entry,
          {'broken': true},
        ]),
      );
      final recovered = CacheService(storage);
      await recovered.initialize();
      expect(recovered.entries, hasLength(1));
      await storage.write(key: CacheService.storageKey, value: 'broken');
      final damaged = CacheService(storage);
      await damaged.initialize();
      expect(damaged.entries, isEmpty);
      expect(damaged.storageError, isNotNull);
    },
  );
  test('server environments cannot restore each other identity', () async {
    await cache.read(path, null, () async => body('A'));
    final other = CacheManager(store, network, 'https://other.example');
    expect(await other.savedIdentity(), isNull);
    await other.activate('alice');
    network.hasNetwork = false;
    await expectLater(
      other.read(path, null, () async => body('B')),
      throwsA(isA<AppException>()),
    );
  });
  test(
    'invalidation rejects an older response and leaves unrelated reads running',
    () async {
      final old = Completer<dynamic>();
      final other = Completer<dynamic>();
      final oldRead = cache.read(path, null, () => old.future);
      final oldAssertion = expectLater(oldRead, throwsA(isA<AppException>()));
      final otherRead = cache.read(
        '/api/resource/Item',
        null,
        () => other.future,
      );
      await cache.invalidate(path);
      await cache.read(path, null, () async => body('new'));
      old.complete(body('old'));
      other.complete(body('item'));
      await oldAssertion;
      expect(await otherRead, body('item'));
      expect(
        store.entries.values.firstWhere((e) => e.endpoint == path).data,
        body('new'),
      );
    },
  );
  test(
    'oversized responses are evicted rather than growing storage indefinitely',
    () async {
      final bounded = CacheService(storage, maxBytes: 1024);
      final manager = CacheManager(bounded, network, 'server');
      await manager.activate('alice');
      await manager.read(path, null, () async => body('A' * 2048));
      expect(bounded.entries, isEmpty);
    },
  );
  test('entry metadata survives serialization', () async {
    await cache.read(path, {'page': 1}, () async => body('A'));
    final entry = store.entries.values.single;
    final restored = CacheEntry.fromJson(entry.toJson());
    expect(restored.toJson(), entry.toJson());
  });
}
