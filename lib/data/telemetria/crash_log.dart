import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/data/remote/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/* BQ 16 (type 1): what % of the app sessions end in a crash, and in which
 * screen, app version, system version and phone model they concentrate.
 * Same events as RegistroFallos in Kotlin:
 *   - "app_session": once per launch.
 *   - "app_crash": when an error nobody caught happens.
 * The backend (GET crashes/report) counts them.
 */
class CrashLog {
  static final String sessionId = const Uuid().v4();
  static Directory? _folder;
  static Map<String, String> _device = {};
  static bool _sessionSent = false;
  static bool _crashSaved = false;

  // =================== 1. CATCH THE CRASH ===================

  static Future<void> install() async {
    // 1. Folder where the crashes wait to be uploaded.
    // 2. Read the phone model and system version once.
    // 3. Catch Flutter errors and async errors nobody caught.
    // 4. Every time someone signs in, upload the session and pending crashes.

    if (kIsWeb) {
      return;
    }
    // 1
    final Directory support = await getApplicationSupportDirectory();
    _folder = Directory('${support.path}/crashes');
    // 2
    _device = await _readDevice();
    // 3
    final FlutterExceptionHandler? previousFlutter = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // An overflow warning is not a crash.
      if (details.library != 'rendering library') {
        _save(details.exception, details.stack);
      }
      previousFlutter?.call(details);
    };
    final ErrorCallback? previousAsync = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _save(error, stack);
      return previousAsync?.call(error, stack) ?? false;
    };
    // 4
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        uploadPending();
      }
    });
  }

  static void _save(Object error, StackTrace? stack) {
    // 1. Only the first crash of the session counts (the backend counts sessions).
    // 2. Write it to a file right away, in case the app closes.
    // 3. Try to upload it now.

    // 1
    final Directory? folder = _folder;
    if (folder == null || _crashSaved) {
      return;
    }
    _crashSaved = true;
    // 2
    try {
      folder.createSync(recursive: true);
      final int now = DateTime.now().millisecondsSinceEpoch;
      final Map<String, Object> crash = {
        'sessionId': sessionId,
        'screen': screenOf(stack),
        'error': error.runtimeType.toString(),
        'appVersion': ApiConfig.appVersion,
        'crashedAt': now,
      };
      File('${folder.path}/crash_$now.json')
          .writeAsStringSync(jsonEncode(crash));
    } catch (_) {
      return;
    }
    // 3
    unawaited(uploadPending());
  }

  /** The first screen file in the stack trace, e.g. "attendance_map_view". */
  static String screenOf(StackTrace? stack) {
    final RegExpMatch? match = RegExp(
      r'package:front_end_flutter/(?:screens|feature)/(?:\w+/)*(\w+)\.dart',
    ).firstMatch('$stack');
    return match?.group(1) ?? 'unknown';
  }

  // =================== 2. UPLOAD ===================

  static Future<void> uploadPending() async {
    // 1. Only with a signed-in user (Firestore needs the uid).
    // 2. Send the session of this launch once.
    // 3. Send every saved crash and delete its file.

    // 1
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    // 2
    if (!_sessionSent) {
      _sessionSent = true;
      _send(uid, 'app_session', {
        'sessionId': sessionId,
        'appVersion': ApiConfig.appVersion,
      });
    }
    // 3
    final Directory? folder = _folder;
    if (folder == null || !folder.existsSync()) {
      return;
    }
    for (final FileSystemEntity file in folder.listSync()) {
      if (file is! File || !file.path.endsWith('.json')) {
        continue;
      }
      try {
        final Map<String, Object> crash = Map<String, Object>.from(
          jsonDecode(file.readAsStringSync()) as Map,
        );
        _send(uid, 'app_crash', crash);
        file.deleteSync();
      } catch (_) {
        // A damaged file is not worth keeping.
        file.deleteSync();
      }
    }
  }

  static void _send(String uid, String name, Map<String, Object> data) {
    // Firestore keeps it on the phone and uploads it when there is internet.
    FirebaseFirestore.instance.collection('events').add({
      ...data,
      ..._device,
      'name': name,
      'teacherId': uid,
      'platform': 'flutter',
      'createdAt': FieldValue.serverTimestamp(),
    }).ignore();
    if (kDebugMode) {
      debugPrint('[fallos] $name enviado (sesión $sessionId)');
    }
  }

  /** Phone model and system version, with the field names the backend groups by. */
  static Future<Map<String, String>> _readDevice() async {
    try {
      final DeviceInfoPlugin plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo android = await plugin.androidInfo;
        return {
          'model': '${android.manufacturer} ${android.model}',
          'androidVersion': '${android.version.sdkInt}',
        };
      }
      if (Platform.isIOS) {
        final IosDeviceInfo ios = await plugin.iosInfo;
        return {
          'model': ios.modelName,
          // The backend calls this field androidVersion; on iPhone it is the iOS version.
          'androidVersion': 'iOS ${ios.systemVersion}',
        };
      }
    } catch (_) {}
    return {};
  }
}
