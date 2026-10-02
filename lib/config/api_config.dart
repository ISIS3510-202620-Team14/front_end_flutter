class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://us-central1-enad-movil.cloudfunctions.net',
  );

  static String get groupsUrl => '$baseUrl/groups';
  static String get studentsUrl => '$baseUrl/students';
  static String get teachersUrl => '$baseUrl/teachers';
  static String get loginUrl => '$baseUrl/login';
  static String get registerUrl => '$baseUrl/register';
}
