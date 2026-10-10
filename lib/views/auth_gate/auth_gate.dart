import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/auth_api/auth_api.dart';
import 'package:front_end_flutter/views/session_view/session_view.dart';
import 'package:front_end_flutter/views/login_view/login_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.sessionStream,
    this.signedInView,
    this.signedOutView,
  });
  final Stream<bool>? sessionStream;
  final Widget? signedInView;
  final Widget? signedOutView;
  @override
  Widget build(BuildContext context) {
    Stream<bool> stream;
    if (sessionStream != null) {
      stream = sessionStream!;
    } else {
      stream = AuthApi.changes.map((User? user) {
        return user != null;
      });
    }
    return StreamBuilder<bool>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No pudimos recuperar la sesión. Vuelve a abrir la aplicación.',
              ),
            ),
          );
        }
        if (snapshot.data == true) {
          return signedInView ?? const SessionView();
        }
        return signedOutView ?? const LoginView();
      },
    );
  }
}
