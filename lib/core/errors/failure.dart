import 'app_exception.dart';

class Failure {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;
  factory Failure.fromException(AppException exception) =>
      Failure(exception.message, code: exception.code);
}
