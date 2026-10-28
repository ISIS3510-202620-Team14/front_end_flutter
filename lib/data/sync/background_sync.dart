import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';

import '../../firebase_options.dart';
import '../remote/api_config.dart';
import '../remote/api_client.dart';
import '../local/offline_database.dart';
import 'offline_runtime.dart';

/** Starts the Android background worker. */
@pragma('vm:entry-point')
void syncDispatcher() {
  Workmanager().executeTask((task, input) async {
    final uid = input?['uid'] as String?;
    if (uid == null) return true;
    OfflineDatabase? db;
    OfflineRuntime? runtime;
    ApiClient? api;
    var completed = false;
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20));
      if (ApiConfig.useEmulators) {
        await FirebaseAuth.instance.useAuthEmulator(
          ApiConfig.emulatorHost,
          ApiConfig.authEmulatorPort,
        );
      }
      final database = OfflineDatabase();
      db = database;
      await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 20),
      );
      if (await database.meta('', 'activeUid') != uid ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        completed = true;
      } else {
        final client = ApiClient(
          localFirst: false,
          tokenProvider: () async {
            if (await database.meta('', 'activeUid') != uid ||
                FirebaseAuth.instance.currentUser?.uid != uid) {
              throw const ApiException(401, 'La sesión cambió.');
            }
            final token = await FirebaseAuth.instance.currentUser!.getIdToken();
            if (token == null ||
                FirebaseAuth.instance.currentUser?.uid != uid ||
                await database.meta('', 'activeUid') != uid) {
              throw const ApiException(401, 'La sesión cambió.');
            }
            return token;
          },
        );
        api = client;
        final worker = OfflineRuntime(uid, database, client, background: true);
        runtime = worker;
        OfflineRuntime.current = worker;
        await worker.synchronize();
        await worker.refreshCounts();
        completed = worker.paused || worker.pending == 0;
      }
    } catch (_) {
      completed = false;
    } finally {
      runtime?.stop();
      OfflineRuntime.current = null;
      api?.dispose();
      try {
        await db?.close();
      } catch (_) {
        completed = false;
      }
    }
    return completed;
  });
}

/** Schedules persistent Android uploads. */
class BackgroundSync {
  static bool _ready = false;

  /** Initializes the scheduler on Android only. */
  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android || _ready) {
      return;
    }
    await Workmanager().initialize(syncDispatcher);
    _ready = true;
  }

  /** Queues uploads without interrupting an active worker. */
  static Future<void> schedule(String uid) async {
    if (!_ready) return;
    await Workmanager().registerOneOffTask(
      'enad-sync-$uid',
      'enad-sync',
      inputData: {'uid': uid},
      existingWorkPolicy: ExistingWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
  }

  /** Cancels queued work for the signed-out account. */
  static Future<void> cancel(String uid) async {
    if (_ready) await Workmanager().cancelByUniqueName('enad-sync-$uid');
  }
}
