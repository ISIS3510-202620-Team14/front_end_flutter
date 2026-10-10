import 'dart:convert';

import 'package:front_end_flutter/services/hours_repository/hours_repository.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/students_repository/students_repository.dart';
import 'package:front_end_flutter/services/group_service/group_service.dart';
import 'package:front_end_flutter/services/student_list_scanner/student_list_scanner.dart';
import 'package:front_end_flutter/services/grouping_analytics_service/grouping_analytics_service.dart';
import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';

void main() {
  ApiClient client(http.Client transport) {
    return ApiClient(
      client: transport,
      tokenProvider: () async {
        return 'fresh-id-token';
      },
    );
  }

  test(
    'import sends school, grade and real codes with a current ID token',
    () async {
      final transport = MockClient((request) async {
        expect(request.url.path, endsWith('/students/import'));
        expect(request.headers['Authorization'], 'Bearer fresh-id-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['schoolId'], 'school-a');
        expect(body['students'][0]['code'], '20262001');
        expect(body['students'][0]['grade'], 5);
        return http.Response(
          '{"created":[{"id":"server-id","code":"20262001"}],"skipped":[]}',
          201,
        );
      });
      final repository = StudentsRepository(api: client(transport));
      final result = await repository.importStudents(
        [ScannedRow('Ana María', code: '20262001')],
        'school-a',
        5,
      );
      expect(result['created'][0]['id'], 'server-id');
      repository.dispose();
    },
  );
  test('unsupported grades never reach the server', () async {
    final repository = StudentsRepository(
      api: client(
        MockClient((request) async {
          fail('Invalid grade must not send a request');
        }),
      ),
    );
    await expectLater(
      repository.importStudents(
        [ScannedRow('Ana María', code: '12345')],
        'school-a',
        2,
      ),
      throwsA(isA<ApiException>()),
    );
    repository.dispose();
  });
  test('an HTTP 200 with stored false never reports hours saved', () async {
    final hours = HoursRepository(
      api: client(
        MockClient((request) async {
          return http.Response('{"stored":false}', 200);
        }),
      ),
    );
    await expectLater(
      hours.save('2026-10-10', {}),
      throwsA(isA<ApiException>()),
    );
    hours.dispose();
  });
  test('missing and duplicate codes fail before any network write', () async {
    int calls = 0;
    final repository = StudentsRepository(
      api: client(
        MockClient((request) async {
          calls++;
          return http.Response('{}', 200);
        }),
      ),
    );
    await expectLater(
      repository.importStudents([ScannedRow('Ana María')], 'school-a', 5),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      repository.importStudents(
        [
          ScannedRow('Ana María', code: '1'),
          ScannedRow('Juan Pérez', code: '1'),
        ],
        'school-a',
        5,
      ),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 0);
    repository.dispose();
  });
  test('group creation uses actual school and teacher', () async {
    final groups = GroupService(
      api: client(
        MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['schoolId'], 'school-a');
          expect(body['teacherId'], 'teacher-a');
          return http.Response('{"id":"group-a"}', 201);
        }),
      ),
    );
    await groups.createGroup(
      name: 'Lectores',
      subject: 'lectura',
      schoolId: 'school-a',
      teacherId: 'teacher-a',
    );
    groups.dispose();
  });
  test('HTTP failure never becomes an empty success response', () async {
    final api = client(
      MockClient((request) async {
        return http.Response('{"error":{"message":"Acceso denegado"}}', 403);
      }),
    );
    await expectLater(
      api.request('GET', 'students'),
      throwsA(
        isA<ApiException>().having(
          (error) {
            return error.message;
          },
          'message',
          'Acceso denegado',
        ),
      ),
    );
    api.dispose();
  });
  test('OCR distinguishes real identifiers from row numbering', () {
    final rows = StudentListScanner.parseRows([
      '1. Ana María 20262001',
      '2. Juan Pérez',
      'Código: AB-123 Luisa Gómez',
    ]);
    expect(rows[0].code, '20262001');
    expect(rows[1].code, '');
    expect(rows[2].code, 'AB-123');
  });
  test('recommendation keeps tolerance and minimum sample size', () {
    final events = [
      for (int index = 0; index < 3; index++)
        GroupingEvent(
          subject: 'lectura',
          classSize: 9,
          method: GroupingMethod.manual,
          teacherId: 'teacher-$index',
          timestamp: DateTime(2026),
        ),
    ];
    final result = GroupingAnalyticsService.fromEvents(events, 10);
    expect(result.recommended, GroupingMethod.manual);
    expect(result.hasEnoughData, true);
    expect(GroupingAnalyticsService.fromEvents(events, 20).sampleSize, 0);
  });
  test('disposed viewmodels ignore delayed notifications', () {
    final notifier = SafeNotifier();
    notifier.dispose();
    expect(notifier.notifyListeners, returnsNormally);
  });
}
