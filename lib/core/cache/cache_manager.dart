import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'cache_entry.dart';
import 'cache_keys.dart';
import 'cache_policy.dart';
import 'cache_service.dart';
import '../errors/app_exception.dart';
import '../network/connectivity_service.dart';

/// Shared repository transport cache. The caller's existing parser is preserved.
class CacheManager extends ChangeNotifier {
  CacheManager(this.store, this.connectivity, this.server);
  final CacheService store;
  final ConnectivityService connectivity;
  final String server;
  String? owner;
  int _epoch = 0;
  int sessionGeneration = 0;
  final Map<String, int> _revisions = {};
  String _group(String path) => path.split('/').take(4).join('/');
  final Map<String, Future<dynamic>> _pending = {};
  final _updates = StreamController<String>.broadcast();
  Stream<String> get updates => _updates.stream;
  bool hasSavedData(String endpoint) => store.entries.values.any(
    (entry) =>
        entry.owner == owner &&
        entry.endpoint == endpoint &&
        entry.key ==
            CacheKeys.request(
              server,
              entry.owner,
              entry.endpoint,
              entry.parameters,
            ),
  );
  bool isRefreshing(String endpoint) =>
      _pending.keys.any((key) => (jsonDecode(key) as List)[4] == endpoint);
  static const _forceKey = #forceApiRefresh;
  static Future<T> force<T>(Future<T> Function() action) =>
      runZoned(action, zoneValues: {_forceKey: true});
  Future<dynamic> read(
    String path,
    Map<String, dynamic>? query,
    Future<dynamic> Function() fetch,
  ) async {
    final policy = CachePolicy.forRequest(path, query);
    final user = owner;
    if (policy == null || user == null) return fetch();
    final key = CacheKeys.request(server, user, path, query);
    final cached = store.entries[key];
    final epoch = _epoch;
    final group = _group(path);
    final revision = _revisions[group] ?? 0;
    Future<dynamic> refresh() => _pending.putIfAbsent(key, () {
      scheduleMicrotask(notifyListeners);
      final future = Future<dynamic>.microtask(() async {
        try {
          final data = await fetch();
          if (epoch != _epoch ||
              user != owner ||
              revision != (_revisions[group] ?? 0)) {
            throw const AppException('The account changed. Please reload.');
          }
          if (!CachePolicy.validReadResponse(path, data)) {
            connectivity.reportRefreshFailure();
            throw const AppException(
              'The server returned an invalid read response.',
            );
          }
          if (CachePolicy.safeResponse(data)) {
            final changed =
                cached == null ||
                CacheKeys.canonical(cached.data) != CacheKeys.canonical(data);
            final now = DateTime.now().toUtc();
            store.entries[key] = CacheEntry(
              key: key,
              endpoint: path,
              parameters: query ?? {},
              data: data,
              owner: user,
              createdAt: cached?.createdAt ?? now,
              updatedAt: now,
              freshFor: policy,
            );
            await store.persist();
            if (changed && cached != null && epoch == _epoch) {
              _updates.add(path);
            }
          }
          if (epoch != _epoch || revision != (_revisions[group] ?? 0)) {
            throw const AppException('The saved data changed. Please reload.');
          }
          return data;
        } on AppException catch (error) {
          if (epoch == _epoch &&
              revision == (_revisions[group] ?? 0) &&
              (error.statusCode == 403 || error.statusCode == 404)) {
            store.entries.remove(key);
            await store.persist();
            if (cached != null) {
              _updates.add(
                path.endsWith('/Has%20Role') ? path : 'revoke:$path',
              );
            }
          }
          rethrow;
        } finally {
          if (epoch == _epoch && revision == (_revisions[group] ?? 0)) {
            _pending.remove(key);
            scheduleMicrotask(notifyListeners);
          }
        }
      });
      return future;
    });
    if (cached != null) {
      if (connectivity.hasNetwork &&
          (!cached.isFresh(DateTime.now().toUtc()) ||
              Zone.current[_forceKey] == true)) {
        // The error is reported by the network service; content stays visible.
        unawaited(refresh().catchError((Object _) => null));
      }
      return cached.data;
    }
    if (!connectivity.hasNetwork) {
      throw const AppException(
        'You are offline. Connect to the internet and tap Retry to load this data for the first time.',
      );
    }
    return refresh();
  }

  Future<void> invalidate(String path) async {
    final segments = path.split('/');
    if (segments.length < 4) return;
    final group = segments.take(4).join('/');
    bool affected(String endpoint) =>
        endpoint == group ||
        endpoint.startsWith('$group/') ||
        (Uri.decodeComponent(group).endsWith('Supplier Point Of Purchase') &&
            endpoint.contains('app_advance'));
    final groups = {
      group,
      for (final key in _pending.keys)
        if (affected((jsonDecode(key) as List)[4] as String))
          _group((jsonDecode(key) as List)[4] as String),
      for (final entry in store.entries.values)
        if (affected(entry.endpoint)) _group(entry.endpoint),
    };
    for (final affectedGroup in groups) {
      _revisions[affectedGroup] = (_revisions[affectedGroup] ?? 0) + 1;
    }
    _pending.removeWhere(
      (key, _) => affected((jsonDecode(key) as List)[4] as String),
    );
    await store.removeWhere((e) => e.owner == owner && affected(e.endpoint));
    _updates.add(group);
    notifyListeners();
  }

  Future<void> activate(String user) async {
    ++sessionGeneration;
    ++_epoch;
    _pending.clear();
    owner = user;
    _revisions.clear();
    try {
      await store.storage.write(
        key: 'offline_identity',
        value: CacheKeys.canonical([server, user]),
      );
    } catch (_) {
      owner = null;
      ++_epoch;
      _pending.clear();
      throw const AppException(
        'Secure storage is unavailable. Please retry signing in.',
      );
    }
  }

  Future<String?> savedIdentity() async {
    final String? raw;
    try {
      raw = await store.storage.read(key: 'offline_identity');
    } catch (_) {
      throw const AppException(
        'Your saved session could not be read. Please sign in again.',
      );
    }
    if (raw == null) return null;
    try {
      final identity = jsonDecode(raw);
      if (identity is List &&
          identity.length == 2 &&
          identity[0] == server &&
          identity[1] is String &&
          (identity[1] as String).isNotEmpty) {
        return identity[1] as String;
      }
    } catch (_) {
      /* Ignore invalid local identity metadata. */
    }
    return null;
  }

  Future<void> clearSession() async {
    ++sessionGeneration;
    final user = owner;
    owner = null;
    _revisions.clear();
    ++_epoch;
    _pending.clear();
    try {
      await store.storage.delete(key: 'offline_identity');
    } catch (_) {
      throw const AppException(
        'The saved session could not be removed. Please retry.',
      );
    } finally {
      await store.removeWhere((entry) => entry.owner == user);
      notifyListeners();
    }
  }
}
