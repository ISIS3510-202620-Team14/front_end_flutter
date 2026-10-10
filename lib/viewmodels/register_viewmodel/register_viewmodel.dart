import 'package:front_end_flutter/services/schools_repository/schools_repository.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/auth_api/auth_api.dart';

class RegisterViewModel extends SafeNotifier {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final SchoolsRepository _schoolsRepository = SchoolsRepository();
  List<Map<String, dynamic>> schools = [];
  final Map<String, Set<String>> selectedSchools = {};
  bool loadingSchools = true;
  String? schoolsError;
  Future<void> loadSchools() async {
    loadingSchools = true;
    schoolsError = null;
    notifyListeners();
    try {
      schools = await _schoolsRepository.load();
    } catch (_) {
      schoolsError = 'No pudimos cargar las instituciones.';
    } finally {
      loadingSchools = false;
      notifyListeners();
    }
  }

  void selectSchool(String id, bool selected) {
    if (selected) {
      selectedSchools[id] = {};
    } else {
      selectedSchools.remove(id);
    }
    notifyListeners();
  }

  void selectCampus(String schoolId, String campusId, bool selected) {
    if (selected) {
      selectedSchools[schoolId]?.add(campusId);
    } else {
      selectedSchools[schoolId]?.remove(campusId);
    }
    notifyListeners();
  }

  bool obscurePassword = true;
  bool isLoading = false;
  String? error;
  bool _disposed = false;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> register() async {
    if (isLoading) {
      return false;
    }
    final email = emailController.text.trim();
    if (nameController.text.trim().isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) ||
        passwordController.text.length < 6) {
      error = 'Escribe tu nombre, un correo válido y una contraseña de al menos 6 caracteres.';
      notifyListeners();
      return false;
    }

    if (selectedSchools.isEmpty || selectedSchools.length > 10) {
      error = 'Selecciona entre una y diez instituciones.';
      notifyListeners();
      return false;
    }
    for (final school in schools) {
      final selected = selectedSchools[school['id']];
      if (selected != null &&
          (school['campuses'] as List? ?? []).isNotEmpty &&
          selected.isEmpty) {
        error = 'Selecciona una sede por institución.';
        notifyListeners();
        return false;
      }
    }
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await AuthApi.register(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        schools: [
          for (final entry in selectedSchools.entries)
            {'schoolId': entry.key, 'campusIds': entry.value.toList()},
        ],
      );
      return true;
    } on AuthError catch (e) {
      error = e.message;
    } catch (_) {
      error = 'No pudimos completar la operación. Intenta de nuevo.';
    } finally {
      isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    _schoolsRepository.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
