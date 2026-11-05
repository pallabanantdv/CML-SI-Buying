import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'cache_entry.dart';

/// A bounded encrypted snapshot using the application's existing OS-backed store.
/// Writes are serialized; unsupported versions and damaged entries are discarded.
class CacheService extends ChangeNotifier {
  CacheService(
    this.storage, {
    this.maxBytes = 2 * 1024 * 1024,
    this.maxEntries = 250,
  });
  final FlutterSecureStorage storage;
  final int maxBytes, maxEntries;
  static const storageKey = 'response_cache_v1';
  final Map<String, CacheEntry> entries = {};
  Future<void> _writes = Future.value();
  String? storageError;
  Future<void> initialize() async {
    try {
      final raw = await storage.read(key: storageKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as List;
      for (final row in decoded) {
        try {
          final entry = CacheEntry.fromJson(
            Map<String, dynamic>.from(row as Map),
          );
          entries[entry.key] = entry;
        } catch (_) {
          debugPrint('Discarding an incompatible cache entry.');
        }
      }
      _bound();
    } catch (_) {
      storageError = 'Saved data could not be read.';
    }
  }

  void _bound() {
    while (entries.length > maxEntries ||
        utf8
                .encode(
                  jsonEncode(entries.values.map((e) => e.toJson()).toList()),
                )
                .length >
            maxBytes) {
      final oldest = entries.values.reduce(
        (a, b) => a.updatedAt.isBefore(b.updatedAt) ? a : b,
      );
      entries.remove(oldest.key);
    }
  }

  Future<void> persist() {
    _bound();
    final snapshot = jsonEncode(entries.values.map((e) => e.toJson()).toList());
    _writes = _writes.then((_) async {
      final previousError = storageError;
      try {
        await storage.write(key: storageKey, value: snapshot);
        storageError = null;
      } catch (_) {
        storageError = 'Saved data could not be updated.';
        debugPrint(storageError);
      }
      if (previousError != storageError) notifyListeners();
    });
    return _writes;
  }

  Future<void> removeWhere(bool Function(CacheEntry) predicate) {
    entries.removeWhere((_, entry) => predicate(entry));
    return persist();
  }
}
