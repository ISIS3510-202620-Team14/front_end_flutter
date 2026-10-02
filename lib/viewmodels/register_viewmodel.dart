import 'package:flutter/material.dart';
import '../services/auth_api.dart';

class RegisterViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
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


  Future<bool> register() async {
    if (isLoading) return false;
    final email = emailController.text.trim();
    if (nameController.text.trim().isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) || passwordController.text.length < 6) {
      error = 'Escribe tu nombre, un correo válido y una contraseña de al menos 6 caracteres.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await AuthApi.register(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
      );
      return true;
    } on AuthError catch (e) {
      error = e.message;
    } catch (_) {
      error = 'No pudimos completar la operación. Intenta de nuevo.';
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
