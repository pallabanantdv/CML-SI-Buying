class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.code,
    this.isAuthenticationError = false,
  });
  final String message;
  final int? statusCode;
  final String? code;
  final bool isAuthenticationError;
  @override
  String toString() => message;
}
