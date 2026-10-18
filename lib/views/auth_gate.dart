import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'login_view.dart';

/// Muestra el login 
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthApi.changes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.cream,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null ? const LoginView() : const HomeShell();
      },
    );
  }
}
