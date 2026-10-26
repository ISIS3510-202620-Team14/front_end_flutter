import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../offline/offline_runtime.dart';
import '../offline/offline_gateway.dart';

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:front_end_flutter/config/api_config/api_config.dart';
import 'package:front_end_flutter/services/auth_api/auth_api.dart';
part 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    Future<String> Function()? tokenProvider,
    bool localFirst = true,
  }) : _localFirst = localFirst && client == null && tokenProvider == null,
       _client = client ?? http.Client(),
       _tokenProvider = tokenProvider ?? AuthApi.getIdToken;
  final bool _localFirst;
  final http.Client _client;
  final Future<String> Function() _tokenProvider;
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final offline = OfflineRuntime.current;
    if (_localFirst && offline != null && OfflineGateway.supports(path)) {
      return OfflineGateway(offline)
          .request(method, path, body ?? {}, query ?? {});
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/$path')
        .replace(queryParameters: query);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      try {
        headers['Authorization'] =
            'Bearer ${await _tokenProvider().timeout(const Duration(seconds: 20))}';
      } on TimeoutException {
        throw const ApiException(
          0,
          'No pudimos conectar para validar la sesión.',
        );
      } on FirebaseAuthException catch (error) {
        throw ApiException(
          error.code == 'network-request-failed' ? 0 : 401,
          'No pudimos validar la sesión. Tus pendientes siguen guardados.',
        );
      }
    }
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw ApiException(
          response.statusCode >= 400 ? response.statusCode : 502,
          'El servidor devolvió una respuesta inválida.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = data['error'];
        String message =
            'No se pudo completar la solicitud (${response.statusCode}).';
        if (error is Map && error['message'] is String) {
          message = error['message'] as String;
        }
        final retry = response.headers['retry-after'];
        int? seconds = int.tryParse(retry ?? '');
        if (seconds == null && retry != null) {
          try {
            seconds = parseHttpDate(retry).difference(DateTime.now()).inSeconds;
          } on FormatException {
            seconds = null;
          }
        }
        throw ApiException(response.statusCode, message, retryAfter: seconds);
      }
      return data;
    } on TimeoutException {
      throw const ApiException(
        0,
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ApiException(0, 'No pudimos conectar. Revisa tu conexión.');
    }
  }

  void dispose() {
    _client.close();
  }
}
