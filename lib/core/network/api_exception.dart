import '../errors/error_mapper.dart';

class ApiException implements Exception, AppError {
  @override
  final String message;
  @override
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
