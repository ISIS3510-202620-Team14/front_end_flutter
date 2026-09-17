import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void login() {
    // TODO: enviar User al servicio de autenticación
    // username: usernameController.text
    // password: passwordController.text)
    // @Juanesillo no se si bajo tu experticie en cyber esto sea buena idea
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
