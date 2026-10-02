import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/school.dart';

/// En debug hablamos con los emuladores locales; al compilar en release,
/// con el backend desplegado. Para un release contra los emuladores:
/// --dart-define=EMULADORES=true
const usarEmuladores = bool.fromEnvironment('EMULADORES') || kDebugMode;

/// El emulador de Android ve tu computador en 10.0.2.2, no en 127.0.0.1.
String get hostLocal =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';

String get _baseUrl => usarEmuladores
    ? 'http://$hostLocal:5001/enad-movil/us-central1'
    : 'https://us-central1-enad-movil.cloudfunctions.net';

/// Error con el mensaje ya listo para mostrar en pantalla.
class AuthError implements Exception {
  final String message;
  AuthError(this.message);
}

/// El backend valida correo y contraseña y devuelve un token.
/// Firebase solo abre la sesión con ese token y la mantiene.
class AuthApi {
  static Stream<User?> get changes => FirebaseAuth.instance.authStateChanges();

  static Future<void> register(
          String name, String email, String password, String schoolId) =>
      _entrar('register', {
        'fullName': name,
        'email': email,
        'password': password,
        'schoolId': schoolId,
      });

  /// Escuelas para el registro. No necesita sesión.
  static Future<List<School>> schools() async {
    final http.Response respuesta;
    try {
      respuesta = await http
          .get(Uri.parse('$_baseUrl/registerSchools'))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw AuthError('No pudimos conectar con el servidor ($_baseUrl).');
    }
    if (respuesta.statusCode != 200) {
      throw AuthError('No pudimos cargar las escuelas. Intenta más tarde.');
    }
    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    return (cuerpo['schools'] as List)
        .map((e) => School.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> login(String email, String password) =>
      _entrar('login', {'email': email, 'password': password});

  static Future<void> logout() => FirebaseAuth.instance.signOut();

  static Future<void> _entrar(String ruta, Map<String, String> datos) async {
    final http.Response respuesta;

    // 1. No llegamos al servidor.
    try {
      respuesta = await http
          .post(
            Uri.parse('$_baseUrl/$ruta'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw AuthError('No pudimos conectar con el servidor ($_baseUrl).');
    }

    Map<String, dynamic>? cuerpo;
    try {
      cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    } catch (_) {
      cuerpo = null;
    }

    if (respuesta.statusCode >= 500 || cuerpo == null) {
      throw AuthError(
          'El servidor falló (${respuesta.statusCode}). Intenta más tarde.');
    }

    if (respuesta.statusCode >= 400) {
      final error = cuerpo['error'] as Map<String, dynamic>?;
      throw AuthError(
          error?['message'] as String? ?? 'Revisa tu correo y tu contraseña.');
    }

    final token = cuerpo['customToken'] as String?;
    if (token == null) {
      throw AuthError('El servidor no devolvió un token. Avisa al equipo.');
    }

    try {
      await FirebaseAuth.instance.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      throw AuthError(e.code == 'network-request-failed'
          ? 'No pudimos conectar con Firebase.'
          : 'Firebase rechazó el token (${e.code}). Avisa al equipo.');
    }
  }
}
