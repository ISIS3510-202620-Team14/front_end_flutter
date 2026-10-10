import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:front_end_flutter/views/login_view/login_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:front_end_flutter/main.dart' as app;
import 'package:front_end_flutter/config/api_config/api_config.dart';
import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:front_end_flutter/models/activity/activity.dart';
import 'package:front_end_flutter/services/auth_api/auth_api.dart';
import 'package:front_end_flutter/services/students_repository/students_repository.dart';
import 'package:front_end_flutter/services/group_service/group_service.dart';
import 'package:front_end_flutter/services/activities_repository/activities_repository.dart';
import 'package:front_end_flutter/services/grouping_analytics_service/grouping_analytics_service.dart';
import 'package:front_end_flutter/services/hours_repository/hours_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android session, students, groups, activities and hours persist through the real emulator contracts',
    (tester) async {
      expect(
        ApiConfig.useEmulators,
        true,
        reason: 'Integration tests must never write production data',
      );
      await app.main();
      await AuthApi.login('flutter.e2e@example.test', 'FlutterTest123!');
      await tester.pumpAndSettle();
      expect(find.text('Educación formativa'), findsOneWidget);
      final stamp = DateTime.now().microsecondsSinceEpoch.toString();
      final students = StudentsRepository();
      final result = await students.importStudents(
        [ScannedRow('Estudiante de Prueba', code: stamp)],
        'flutter-e2e-school',
        5,
      );
      expect((result['created'] as List).length, 1);
      final existing = await students.importStudents(
        [ScannedRow('Estudiante de Prueba', code: stamp)],
        'flutter-e2e-school',
        5,
      );
      expect((existing['skipped'] as List).length, 1);
      final roster = await students.fetchStudents();
      final student = roster.firstWhere((item) {
        return item.code == stamp;
      });
      expect(student.id.startsWith('local-'), false);
      final assessed = await students.setLevel(student, 'Lectura', 'Letra');
      expect(assessed.levels['Lectura'], 'Letra');
      final reloaded = (await students.fetchStudents()).firstWhere((item) {
        return item.id == student.id;
      });
      expect(reloaded.levels['Lectura'], 'Letra');
      await tester.tap(find.text('Mi lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actualizar lista'));
      await tester.pumpAndSettle();
      expect(find.text('Estudiante de Prueba'), findsWidgets);
      final groups = GroupService();
      final group = await groups.createGroup(
        name: 'Lectores $stamp',
        subject: 'lectura',
        schoolId: 'flutter-e2e-school',
      );
      final id = group['id'] as String;
      await groups.addStudentToGroup(id, student.id);
      expect(
        (await groups.fetchGroupDetail(id))['studentIds'],
        contains(student.id),
      );
      await groups.renameGroup(id, 'Grupo actualizado');
      expect((await groups.fetchGroupDetail(id))['name'], 'Grupo actualizado');
      final grouping = GroupingAnalyticsService();
      await grouping.trackGroupingEvent(
        GroupingEvent(
          subject: 'lectura',
          classSize: roster.length,
          method: GroupingMethod.manual,
          teacherId: 'flutter-e2e-teacher',
          timestamp: DateTime.now(),
        ),
      );
      final activities = ActivitiesRepository();
      final activity = CustomActivity(
        id: stamp,
        title: 'Lectura de prueba',
        subject: 'Lectura',
        minutes: 20,
      );
      await activities.save(activity, DateTime.now());
      await activities.save(activity, DateTime.now());
      final event = await FirebaseFirestore.instance
          .collection('events')
          .doc('flutter_activity_$stamp')
          .get();
      expect(event.data()?['platform'], 'flutter');
      await AuthApi.logout();
      await tester.pumpAndSettle();
      expect(find.byType(LoginView), findsOneWidget);
      await AuthApi.login('flutter.e2e@example.test', 'FlutterTest123!');
      await tester.pumpAndSettle();
      final restored = await ActivitiesRepository().load(DateTime.now());
      expect(
        restored.where((item) {
          return item.id == stamp;
        }).length,
        1,
      );
      final hours = HoursRepository();
      final date = ActivitiesRepository.dateKey(DateTime.now());
      await hours.save(date, {
        'schoolId': 'flutter-e2e-school',
        'plannedHours': 2,
        'workedHours': 1,
        'origin': 'manual',
        'presentAtCampus': false,
        'reason': 'Prueba controlada',
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'platform': 'flutter',
        'appVersion': '1.0.0',
      });
      expect((await hours.load(date))?['workedHours'], 1);
      for (final label in ['Grupos', 'Horas', 'Mis datos', 'Hoy']) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }
      expect(find.text('Educación formativa'), findsOneWidget);
      await groups.removeStudentFromGroup(id, student.id);
      await groups.deleteGroup(id);
      students.dispose();
      groups.dispose();
      grouping.dispose();
      hours.dispose();
    },
  );
}
