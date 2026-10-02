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
  // Un docente puede trabajar en varias instituciones y, en cada una, en varias sedes.
  // Llave: id de la institución; valor: ids de las sedes elegidas en ella.
  final Map<String, Set<String>> selectedCampuses = {};
  bool isLoadingSchools = true;

  // Si el back alcanzó a enviar el correo de bienvenida al crear la cuenta.
  bool welcomeEmailSent = false;

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

  bool isSchoolSelected(String schoolId) =>
      selectedCampuses.containsKey(schoolId);

  bool isCampusSelected(String schoolId, String campusId) =>
      selectedCampuses[schoolId]?.contains(campusId) ?? false;

  void toggleSchool(String schoolId) {
    if (selectedCampuses.remove(schoolId) == null) {
      selectedCampuses[schoolId] = {};
    }
    notifyListeners();
  }

  void toggleCampus(String schoolId, String campusId) {
    final sedes = selectedCampuses[schoolId];
    if (sedes == null) return;
    if (!sedes.remove(campusId)) sedes.add(campusId);
    notifyListeners();
  }

  // Mensaje si falta elegir algo, o null si la selección está completa.
  String? _faltaSeleccion() {
    if (selectedCampuses.isEmpty) return 'Elige al menos una institución.';
    for (final school in schools) {
      final sedes = selectedCampuses[school.id];
      if (sedes != null && school.campuses.isNotEmpty && sedes.isEmpty) {
        return 'Elige al menos una sede de ${school.name}.';
      }
    }
    return null;
  }

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }


  Future<bool> register() async {
    final falta = _faltaSeleccion();
    if (falta != null) {
      error = falta;
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      welcomeEmailSent = await AuthApi.register(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        {
          for (final e in selectedCampuses.entries) e.key: e.value.toList(),
        },
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
