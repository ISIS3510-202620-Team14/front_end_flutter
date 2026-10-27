import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/services/offline/offline_runtime.dart';
import 'package:front_end_flutter/services/auth_api/auth_api.dart';
import 'package:front_end_flutter/models/user_profile/user_profile.dart';
import 'package:front_end_flutter/services/profile_repository/profile_repository.dart';
import 'package:front_end_flutter/services/schools_repository/schools_repository.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';

/** Loads data only for the current account. */
class SessionViewModel extends SafeNotifier {
  /** Accepts repositories for session loading. */
  SessionViewModel({ProfileRepository? profiles, SchoolsRepository? schools})
    : _profiles = profiles ?? ProfileRepository(),
      _schools = schools ?? SchoolsRepository();
  final ProfileRepository _profiles;
  final SchoolsRepository _schools;
  UserProfile? profile;
  List<Map<String, dynamic>> schools = [];
  bool loading = true;
  String? error;
  int _loadId = 0;
  /** Ignores results from replaced sessions or older loads. */
  Future<void> load() async {
    final request = ++_loadId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    loading = true;
    error = null;
    profile = null;
    schools = [];
    notifyListeners();
    /** Checks that this load still belongs to the active account. */
    bool isCurrent() {
      return !disposed &&
          request == _loadId &&
          FirebaseAuth.instance.currentUser?.uid == uid;
    }

    try {
      if (uid == null) throw StateError('No active session');
      if (await OfflineRuntime.hasDownload(uid)) {
        if (!isCurrent()) return;
        await OfflineRuntime.open(uid);
      }
      if (!isCurrent()) return;
      var loaded = await _profiles.load();
      if (!isCurrent()) return;
      if (loaded.role != 'docente') {
        profile = loaded;
        return;
      }
      if (OfflineRuntime.current?.uid != uid) {
        await OfflineRuntime.open(uid);
        if (!isCurrent()) return;
        loaded = await _profiles.load();
      }
      if (!isCurrent()) return;
      final available = await _schools.load();
      if (!isCurrent()) return;
      schools = available.where((school) {
        return loaded.schoolIds.contains(school['id']);
      }).toList();
      profile = UserProfile(
        uid: loaded.uid,
        name: loaded.name,
        email: loaded.email,
        role: loaded.role,
        active: loaded.active,
        campusIds: loaded.campusIds,
        schoolIds: schools.map((Map<String, dynamic> school) {
          return school['id'] as String;
        }).toList(),
      );
    } catch (_) {
      if (isCurrent()) {
        error =
            'No pudimos cargar tu perfil e instituciones. Intenta de nuevo.';
      }
    } finally {
      if (isCurrent()) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    await AuthApi.logout();
  }

  Future<void> saveName(String name) async {
    await _profiles.updateName(name);
    await load();
  }

  @override
  void dispose() {
    _schools.dispose();
    super.dispose();
  }
}
