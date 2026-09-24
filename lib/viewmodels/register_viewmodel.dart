import 'package:flutter/material.dart';
import '../services/auth_api.dart';

class RegisterViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;
  String? error;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }


  Future<bool> register() async {
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
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
