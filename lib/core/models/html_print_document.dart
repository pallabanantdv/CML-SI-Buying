import 'dart:convert';
import 'dart:typed_data';

import '../errors/app_exception.dart';

class HtmlPrintDocument {
  const HtmlPrintDocument({
    required this.html,
    required this.title,
    this.baseUrl,
    this.documentId,
    this.cookies = const {},
    this.loadPdf,
  });

  final String html;
  final String title;
  final Uri? baseUrl;
  final String? documentId;
  final Map<String, String> cookies;
  final Future<Uint8List> Function()? loadPdf;

  /// Accept raw printview HTML and the supported Frappe method wrappers.
  static String extractHtml(dynamic response) {
    dynamic value = response;
    if (value is String && value.trimLeft().startsWith('{')) {
      try {
        value = jsonDecode(value);
      } catch (_) {}
    }
    if (value is Map) value = value['message'] ?? value['html'];
    if (value is Map) value = value['html'];
    if (value is! String ||
        value.trim().isEmpty ||
        !RegExp(
          r'<(?:!doctype|html|body|div|table|section|article|p|h[1-6])\b',
          caseSensitive: false,
        ).hasMatch(value)) {
      throw const AppException(
        'No valid print document was returned. Please retry.',
      );
    }
    if (value.toLowerCase().contains('login required') ||
        RegExp(
          r'<input[^>]+type=["\x27]password',
          caseSensitive: false,
        ).hasMatch(value)) {
      throw const AppException(
        'Your session has expired. Please sign in again.',
      );
    }
    if (!RegExp(r'<html\b', caseSensitive: false).hasMatch(value)) {
      value =
          '<!DOCTYPE html><html><head><meta charset="utf-8"></head><body>$value</body></html>';
    }
    // Preserve the server CSS and viewport when present. A desktop-sized
    // default lets fixed print layouts fit initially and remain zoomable.
    if (!RegExp(
      r'<meta[^>]+name=["\x27]viewport',
      caseSensitive: false,
    ).hasMatch(value)) {
      value = value.replaceFirst(
        RegExp(r'<head[^>]*>', caseSensitive: false),
        '<head><meta name="viewport" content="width=980, user-scalable=yes">',
      );
    }
    return value;
  }
}
