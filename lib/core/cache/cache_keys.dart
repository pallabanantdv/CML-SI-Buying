import 'dart:convert';

/// Map order is insignificant; list order (including filters) is significant.
abstract final class CacheKeys {
  static String canonical(dynamic value) => jsonEncode(_sort(value));
  static dynamic _sort(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final key in keys) key: _sort(value[key])};
    }
    if (value is List) return value.map(_sort).toList();
    return value;
  }

  static String request(
    String server,
    String owner,
    String path,
    Map<String, dynamic>? parameters,
  ) => canonical([1, server, owner, 'GET', path, parameters ?? {}]);
}
