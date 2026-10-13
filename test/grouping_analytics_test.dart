import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/grouping_analytics_service/grouping_analytics_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _event(String method, {int size = 12}) => {
      'subject': 'matematicas',
      'classSize': size,
      'method': method,
      'teacherId': 'uid-1',
      'timestamp': '2026-10-01T10:00:00.000Z',
    };

GroupingAnalyticsService _service(http.Client client) =>
    GroupingAnalyticsService(
      api: ApiClient(client: client, tokenProvider: () async => 'token-de-prueba'),
    );

void main() {
  test('sin eventos recomienda automático sin datos suficientes', () async {
    final service = _service(
      MockClient((_) async => http.Response(jsonEncode({'events': []}), 200)),
    );

    final rec = await service.recommend(subject: 'matematicas', classSize: 12);

    expect(rec.recommended, GroupingMethod.automatic);
    expect(rec.hasEnoughData, isFalse);
  });

  test('elige el método mayoritario y manda el token', () async {
    String? authHeader;
    final service = _service(
      MockClient((request) async {
        authHeader = request.headers['Authorization'];
        return http.Response(
          jsonEncode({
            'events': [
              _event('manual'),
              _event('manual'),
              _event('manual'),
              _event('automatic'),
              _event('manual', size: 40), // fuera de la tolerancia (±5)
            ],
          }),
          200,
        );
      }),
    );

    final rec = await service.recommend(subject: 'matematicas', classSize: 12);

    expect(authHeader, 'Bearer token-de-prueba');
    expect(rec.recommended, GroupingMethod.manual);
    expect(rec.sampleSize, 4);
    expect(rec.confidence, 0.75);
    expect(rec.hasEnoughData, isTrue);
  });

  test('la tolerancia crece con el tamaño de la clase', () {
    GroupingEvent at(int size) => GroupingEvent(
          subject: 'matematicas',
          classSize: size,
          method: GroupingMethod.manual,
          teacherId: 'uid-1',
          timestamp: DateTime(2026, 10, 1),
        );

    // Clase de 8 (±3): entra el de 11, no el de 12.
    expect(GroupingAnalyticsService.fromEvents([at(11)], 8).sampleSize, 1);
    expect(GroupingAnalyticsService.fromEvents([at(12)], 8).sampleSize, 0);
    // Clase de 30 (±8): entra el de 38, no el de 39.
    expect(GroupingAnalyticsService.fromEvents([at(38)], 30).sampleSize, 1);
    expect(GroupingAnalyticsService.fromEvents([at(39)], 30).sampleSize, 0);
  });

  test('si el backend falla, recommend propaga el error', () async {
    final service = _service(
      MockClient((_) async => http.Response('{"error":{"message":"x"}}', 500)),
    );

    expect(
      () => service.recommend(subject: 'matematicas', classSize: 12),
      throwsA(isA<ApiException>()),
    );
  });
}
