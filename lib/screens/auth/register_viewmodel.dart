// lib/screens/auth/register_viewmodel.dart
import 'package:front_end_flutter/data/repository/schools_repository.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/auth/auth_api.dart';
import 'package:front_end_flutter/data/auth/credential_rules.dart';

class RegisterViewModel extends SafeNotifier {
  RegisterViewModel({SchoolsRepository? schools})
    : _schoolsRepository = schools ?? SchoolsRepository();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final SchoolsRepository _schoolsRepository;
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
      schoolsError = 'No pudimos cargar las instituciones. Revisa tu internet.';
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
    error = null;
    notifyListeners();
  }

  void selectCampus(String schoolId, String campusId, bool selected) {
    if (selected) {
      selectedSchools[schoolId]?.add(campusId);
    } else {
      selectedSchools[schoolId]?.remove(campusId);
    }
    error = null;
    notifyListeners();
  }

  bool obscurePassword = true;
  bool isLoading = false;
  String? error;

  /** The bool represents whether the backend managed to send the welcome email after registration. */
  bool welcomeEmailSent = false;

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

  Future<bool> register() async {
    if (isLoading) {
      return false;
    }
    final email = emailController.text.trim();
    if (nameController.text.trim().isEmpty ||
        !CredentialRules.isValidEmail(email) ||
        passwordController.text.length < CredentialRules.minPasswordLength) {
      error =
          'Escribe tu nombre, un correo válido y una contraseña de al menos ${CredentialRules.minPasswordLength} caracteres.';
      notifyListeners();
      return false;
    }

    if (selectedSchools.isEmpty) {
      error = 'Elige al menos una institución.';
      notifyListeners();
      return false;
    }
    if (selectedSchools.length > 10) {
      error = 'Elige máximo 10 instituciones.';
      notifyListeners();
      return false;
    }
    for (final school in schools) {
      final selected = selectedSchools[school['id']];
      if (selected != null &&
          (school['campuses'] as List? ?? []).isNotEmpty &&
          selected.isEmpty) {
        error = 'Elige al menos una sede de ${school['name']}.';
        notifyListeners();
        return false;
      }
    }
    isLoading = true;
    error = null;
    welcomeEmailSent = false;
    notifyListeners();

    try {
      welcomeEmailSent = await AuthApi.register(
        nameController.text.trim(),
        email,
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
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _schoolsRepository.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
