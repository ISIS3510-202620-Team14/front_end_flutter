import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:front_end_flutter/main.dart' as app;
import 'package:front_end_flutter/config/api_config/api_config.dart';
import 'package:front_end_flutter/services/activities_repository/activities_repository.dart';
import 'package:front_end_flutter/services/hours_repository/hours_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'a new Android process restores the session, plan and hours receipt',
    (tester) async {
      expect(
        ApiConfig.useEmulators,
        true,
        reason: 'Never run fixtures against production',
      );
      await app.main();
      final user = await FirebaseAuth.instance.authStateChanges().first;
      expect(user?.uid, 'flutter-e2e-teacher');
      await tester.pumpAndSettle();
      expect(find.text('Educación formativa'), findsOneWidget);
      final activities = await ActivitiesRepository().load(DateTime.now());
      expect(
        activities.any((activity) {
          return activity.title == 'Lectura de prueba';
        }),
        true,
      );
      final hours = HoursRepository();
      expect(
        (await hours.load(
          ActivitiesRepository.dateKey(DateTime.now()),
        ))?['workedHours'],
        1,
      );
      hours.dispose();
    },
  );
}
