// lib/screens/auth/login_viewmodel.dart
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/auth/auth_api.dart';
import 'package:front_end_flutter/data/auth/credential_rules.dart';

class LoginViewModel extends SafeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;
  String? error;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  /** Hides the last error as soon as the teacher starts fixing the form. */
  void clearError() {
    if (error == null) {
      return;
    }
    error = null;
    notifyListeners();
  }

  /** Returns true when the session was opened. */
  Future<bool> login() async {
    if (isLoading) {
      return false;
    }
    final email = emailController.text.trim();
    if (!CredentialRules.isValidEmail(email) ||
        passwordController.text.isEmpty) {
      error = 'Escribe un correo válido y tu contraseña.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await AuthApi.login(email, passwordController.text);
      return true;
    } on AuthError catch (e) {
      error = e.message;
    } catch (_) {
      error = 'No pudimos completar la operación. Intenta de nuevo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
