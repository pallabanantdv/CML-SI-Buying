import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppEnvironment {
  static const _definedFrappeBaseUrl = String.fromEnvironment(
    'FRAPPE_BASE_URL',
  );

  static String get frappeBaseUrl {
    final definedValue = _definedFrappeBaseUrl.trim();
    final value = definedValue.isNotEmpty
        ? definedValue
        : kReleaseMode
        ? ''
        : dotenv.env['FRAPPE_BASE_URL']?.trim() ?? '';
    if (value.isEmpty || value.contains('your-erpnext-domain.com')) return '';
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
