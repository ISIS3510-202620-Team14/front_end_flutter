class StudentAge {
  static const int minimum = 5;
  static const int maximum = 18;

  static bool isValid(String value) {
    final int? age = int.tryParse(value.trim());
    return age != null && age >= minimum && age <= maximum;
  }

  static String? validate(String? value) {
    if (!isValid(value ?? '')) {
      return 'Escribe una edad entre 5 y 18 años.';
    }
    return null;
  }
}
