part of 'api_client.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.retryAfter});
  final int? retryAfter;
  final int statusCode;
  final String message;
  @override
  String toString() {
    return message;
  }
}
