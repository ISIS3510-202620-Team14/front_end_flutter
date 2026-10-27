import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/firebase_options.dart';
import 'package:front_end_flutter/data/remote/api_config.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/screens/auth/auth_gate.dart';

import 'data/sync/background_sync.dart';
part 'app/my_app.dart';

/** Initializes Firebase and opens the app. */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (ApiConfig.useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(
      ApiConfig.emulatorHost,
      ApiConfig.authEmulatorPort,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      ApiConfig.emulatorHost,
      ApiConfig.firestoreEmulatorPort,
    );
  }

  await BackgroundSync.initialize();
  runApp(const MyApp());
}
