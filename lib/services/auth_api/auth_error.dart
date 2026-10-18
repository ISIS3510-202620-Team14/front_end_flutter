part of 'auth_api.dart';

class AuthError implements Exception {
  AuthError(this.message);
  final String message;
  @override
  String toString() {
    return message;
  }
}
