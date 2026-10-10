import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:front_end_flutter/models/user_profile/user_profile.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/schools_repository/schools_repository.dart';
import 'package:front_end_flutter/viewmodels/session_viewmodel/session_viewmodel.dart';

import 'fakes/fake_profile_repository.dart';

void main() {
  test(
    'session exposes only authorized institutions and their campuses',
    () async {
      final profile = UserProfile.fromJson('teacher-a', {
        'fullName': 'Docente',
        'email': 'teacher@example.test',
        'rol': 'docente',
        'activo': true,
        'schoolIds': ['school-a'],
      });
      final session = SessionViewModel(
        profiles: FakeProfileRepository(profile),
        schools: SchoolsRepository(
          api: ApiClient(
            client: MockClient((request) async {
              return http.Response(
                '{"schools":[{"id":"school-a","name":"A","campuses":["Sede A"]},{"id":"school-b","name":"B"}]}',
                200,
              );
            }),
          ),
        ),
      );
      await session.load();
      expect(session.schools.length, 1);
      expect(session.schools.first['id'], 'school-a');
      expect(session.schools.first['campuses'], ['Sede A']);
      expect(session.profile!.canTeach, true);
      session.dispose();
    },
  );
  test('inactive, administrator and schoolless accounts cannot enter teacher flows', () {
    for (final data in [
      {
        'rol': 'docente',
        'activo': false,
        'schoolIds': ['school-a'],
      },
      {
        'rol': 'admin',
        'activo': true,
        'schoolIds': ['school-a'],
      },
      {'rol': 'docente', 'activo': true, 'schoolIds': <String>[]},
    ]) {
      expect(UserProfile.fromJson('teacher-a', data).canTeach, false);
    }
  });
}
