import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppEnvironment {
  static String get frappeBaseUrl {
    final value = dotenv.env['FRAPPE_BASE_URL']?.trim() ?? '';
    if (value.isEmpty || value.contains('your-erpnext-domain.com')) return '';
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
