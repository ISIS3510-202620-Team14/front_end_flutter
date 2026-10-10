import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_end_flutter/views/auth_gate/auth_gate.dart';
import 'package:front_end_flutter/widgets/home_bottom_nav/home_bottom_nav.dart';

void main() {
  testWidgets(
    'restores and closes the session without initializing Firebase in tests',
    (tester) async {
      final sessions = StreamController<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            sessionStream: sessions.stream,
            signedInView: const Text('Sesión abierta'),
            signedOutView: const Text('Iniciar sesión'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      sessions.add(false);
      await tester.pump();
      await tester.pump();
      expect(find.text('Iniciar sesión'), findsOneWidget);
      sessions.add(true);
      await tester.pump();
      await tester.pump();
      expect(find.text('Sesión abierta'), findsOneWidget);
      sessions.add(false);
      await tester.pump();
      await tester.pump();
      expect(find.text('Iniciar sesión'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      sessions.close();
    },
  );
  testWidgets('each bottom navigation entry emits its own destination', (
    tester,
  ) async {
    int selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: HomeBottomNav(
            currentIndex: 0,
            onSelect: (index) {
              selected = index;
            },
          ),
        ),
      ),
    );
    final labels = ['Hoy', 'Mi lista', 'Grupos', 'Horas', 'Mis datos'];
    for (int index = 0; index < labels.length; index++) {
      await tester.tap(find.text(labels[index]));
      expect(selected, index);
    }
  });
}
