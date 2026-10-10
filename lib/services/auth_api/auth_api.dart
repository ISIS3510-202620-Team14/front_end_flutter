import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/analytics_service/analytics_service.dart';
part 'auth_error.dart';

class AuthApi {
  static Stream<User?> get changes {
    return FirebaseAuth.instance.authStateChanges();
  }

  static Future<void> register(
    String name,
    String email,
    String password, {
    List<Map<String, dynamic>> schools = const [],
  }) async {
    await _enter('register', {
      'fullName': name,
      'email': email,
      'password': password,
      'schools': schools,
    });
  }

  static Future<void> login(String email, String password) async {
    await _enter('login', {'email': email, 'password': password});
  }

  static Future<String> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AuthError('Inicia sesión para continuar.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw AuthError('Inicia sesión de nuevo.');
    }
    return token;
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> _enter(String route, Map<String, dynamic> body) async {
    final api = ApiClient();
    try {
      final data = await api.request(
        'POST',
        route,
        body: body,
        authenticated: false,
      );
      final token = data['customToken'];
      if (token is! String) {
        throw AuthError('El servidor no devolvió una sesión válida.');
      }
      await FirebaseAuth.instance.signInWithCustomToken(token);
      String eventName = 'login';
      if (route == 'register') {
        eventName = 'sign_up';
      }
      await AnalyticsService.instance.log(eventName, {'method': 'password'});
    } on ApiException catch (error) {
      throw AuthError(error.message);
    } on FirebaseAuthException {
      throw AuthError('No pudimos abrir la sesión. Revisa tu conexión.');
    } finally {
      api.dispose();
    }
  }
}
