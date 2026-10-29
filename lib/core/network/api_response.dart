class ApiResponse {
  const ApiResponse({required this.data, this.statusCode, this.headers});
  final dynamic data;
  final int? statusCode;
  final Map<String, List<String>>? headers;
}
