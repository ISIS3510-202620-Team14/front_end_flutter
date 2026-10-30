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

  /** Returns whether Brevo accepted the welcome email request. */
  static Future<bool> register(
    String name,
    String email,
    String password, {
    List<Map<String, dynamic>> schools = const [],
    ApiClient? client,
    Future<void> Function(String)? signIn,
    Future<void> Function(String, Map<String, Object>)? logEvent,
  }) async {
    return _enter(
      'register',
      {
        'fullName': name,
        'email': email,
        'password': password,
        'schools': schools,
      },
      client: client,
      signIn: signIn,
      logEvent: logEvent,
    );
  }

  /** Opens a session with optional adapters for isolated tests. */
  static Future<void> login(
    String email,
    String password, {
    ApiClient? client,
    Future<void> Function(String)? signIn,
    Future<void> Function(String, Map<String, Object>)? logEvent,
  }) async {
    await _enter(
      'login',
      {'email': email, 'password': password},
      client: client,
      signIn: signIn,
      logEvent: logEvent,
    );
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

  /** Authentication succeeds independently from optional telemetry. */
  static Future<bool> _enter(
    String route,
    Map<String, dynamic> body, {
    ApiClient? client,
    Future<void> Function(String)? signIn,
    Future<void> Function(String, Map<String, Object>)? logEvent,
  }) async {
    final api = client ?? ApiClient();
    try {
      final data = await api.request(
        'POST',
        route,
        body: body,
        authenticated: false,
      );
      final token = data['customToken'];
      if (token is! String || token.trim().isEmpty) {
        throw AuthError('El servidor no devolvió una sesión válida.');
      }
      ReportsRepository.clearCache();
      if (signIn != null) {
        await signIn(token);
      } else {
        await FirebaseAuth.instance.signInWithCustomToken(token);
      }
      String eventName = 'login';
      if (route == 'register') {
        eventName = 'sign_up';
      }
      // # samuel charry contribution: F28 telemetry cannot undo a valid login.
      try {
        final log = logEvent ?? AnalyticsService.instance.log;
        await log(eventName, {
          'method': 'password',
        }).timeout(const Duration(seconds: 2));
      } catch (_) {}
      // Only register sends welcomeEmailSent
      return data['welcomeEmailSent'] == true;
    } on ApiException catch (error) {
      throw AuthError(error.message);
    } on FirebaseAuthException {
      throw AuthError('No pudimos abrir la sesión. Revisa tu conexión.');
    } finally {
      if (client == null) api.dispose();
    }
  }
}
