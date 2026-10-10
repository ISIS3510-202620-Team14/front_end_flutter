import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int authEmulatorPort = int.fromEnvironment(
    'AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );
  static const int firestoreEmulatorPort = int.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );
  static const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');
  static String get emulatorHost {
    const configured = String.fromEnvironment('EMULATOR_HOST');
    if (configured.isNotEmpty) {
      return configured;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }
    if (useEmulators) {
      return 'http://$emulatorHost:5001/enad-movil/us-central1';
    }
    return 'https://us-central1-enad-movil.cloudfunctions.net';
  }

  static String get groupsUrl {
    return '$baseUrl/groups';
  }

  static String get studentsUrl {
    return '$baseUrl/students';
  }

  static String get teachersUrl {
    return '$baseUrl/teachers';
  }

  static String get loginUrl {
    return '$baseUrl/login';
  }

  static String get registerUrl {
    return '$baseUrl/register';
  }
}
