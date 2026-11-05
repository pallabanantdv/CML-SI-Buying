import '../../config/constants/api_endpoints.dart';

/// Explicit read allowlist. Authentication and unreviewed methods are excluded.
abstract final class CachePolicy {
  static Duration? forRequest(String path, Map<String, dynamic>? query) {
    if (path == '/api/method/${ApiEndpoints.supplierAdvance}') {
      return const Duration(minutes: 5);
    }
    final segments = Uri.decodeComponent(path).split('/');
    if (segments.length < 4 || !path.startsWith('/api/resource/')) return null;
    final type = segments[3];
    if (type == 'User') {
      if (segments.length != 4 || query?['fields'] == null) return null;
      return const Duration(minutes: 30);
    }
    if (!const {
      'Supplier',
      'Supplier Point Of Purchase',
      'Has Role',
      'Item',
      'Journal Entry',
      'Warehouse',
      'Island',
      'Company',
      'Account',
      'Mode of Payment',
      'UOM',
    }.contains(type)) {
      return null;
    }
    return Duration(
      minutes: type == 'Supplier Point Of Purchase' && segments.length == 4
          ? 5
          : 10,
    );
  }

  static bool validReadResponse(String path, dynamic body) {
    if (body is! Map) return false;
    if (path.startsWith('/api/resource/')) {
      final data = body['data'];
      return path.split('/').length == 4
          ? data is List && data.every((row) => row is Map)
          : data is Map;
    }
    final message = body['message'];
    return message is List && message.every((row) => row is Map);
  }

  static bool safeResponse(dynamic body) {
    if (body is! Map ||
        body['exception'] != null ||
        body['exc_type'] != null ||
        body['_server_messages'] != null) {
      return false;
    }
    if (!body.containsKey('data') && !body.containsKey('message')) return false;
    return !_hasSecret(body);
  }

  static bool _hasSecret(dynamic value) {
    if (value is Map) {
      for (final entry in value.entries) {
        if (RegExp(
              r'password|secret|token|cookie|authorization|api_key|reset_key',
              caseSensitive: false,
            ).hasMatch(entry.key.toString()) ||
            _hasSecret(entry.value)) {
          return true;
        }
      }
    }
    if (value is List) return value.any(_hasSecret);
    return false;
  }
}
