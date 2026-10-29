// lib/data/auth/auth_api.dart
import '../sync/offline_runtime.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/data/telemetria/analytics_service.dart';
part 'auth_error.dart';

/** Opens and closes the authenticated session. */
class AuthApi {
  static Stream<User?> get changes {
    return FirebaseAuth.instance.authStateChanges();
  }

  /** Returns whether the backend managed to send the welcome email (Brevo). */
  static Future<bool> register(
    String name,
    String email,
    String password, {
    List<Map<String, dynamic>> schools = const [],
  }) async {
    return _enter('register', {
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

  /** Stops uploads before signing out. */
  static Future<void> logout() async {
    ReportsRepository.clearCache();
    await OfflineRuntime.clearActiveSession();
    await FirebaseAuth.instance.signOut();
  }

  static Future<bool> _enter(String route, Map<String, dynamic> body) async {
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
      ReportsRepository.clearCache();
      await FirebaseAuth.instance.signInWithCustomToken(token);
      String eventName = 'login';
      if (route == 'register') {
        eventName = 'sign_up';
      }
      await AnalyticsService.instance.log(eventName, {'method': 'password'});
      // Only register sends welcomeEmailSent
      return data['welcomeEmailSent'] == true;
    } on ApiException catch (error) {
      throw AuthError(error.message);
    } on FirebaseAuthException {
      throw AuthError('No pudimos abrir la sesión. Revisa tu conexión.');
    } finally {
      api.dispose();
    }
  }
}
