abstract final class AppNumberFormat {
  /// Display only: values sent to ERP retain their original numeric types.
  static String amount(num value) {
    if (!value.isFinite) return value.toString();
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '$whole.${parts.last}';
  }
}
