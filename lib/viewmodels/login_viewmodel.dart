import 'package:flutter/material.dart';
import '../services/auth_api.dart';

class LoginViewModel extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;
  String? error;
  bool _disposed = false;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> login() async {
    if (isLoading) return;
    final email = emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) || passwordController.text.isEmpty) {
      error = 'Escribe un correo válido y tu contraseña.';
      notifyListeners();
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await AuthApi.login(emailController.text.trim(), passwordController.text);
      return;
    } on AuthError catch (e) {
      error = e.message;
    } catch (_) {
      error = 'No pudimos completar la operación. Intenta de nuevo.';
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
