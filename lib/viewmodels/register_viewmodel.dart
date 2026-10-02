import 'package:flutter/material.dart';
import '../models/school.dart';
import '../services/auth_api.dart';

class RegisterViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;
  String? error;

  List<School> schools = [];
  String? selectedSchoolId;
  bool isLoadingSchools = true;

  RegisterViewModel() {
    loadSchools();
  }

  Future<void> loadSchools() async {
    isLoadingSchools = true;
    notifyListeners();
    try {
      schools = await AuthApi.schools();
    } on AuthError catch (e) {
      error = e.message;
    }
    isLoadingSchools = false;
    notifyListeners();
  }

  void selectSchool(String? id) {
    selectedSchoolId = id;
    notifyListeners();
  }

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }


  Future<bool> register() async {
    if (selectedSchoolId == null) {
      error = 'Elige tu escuela.';
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
        selectedSchoolId!,
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
