// lib/screens/auth/session_viewmodel.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/data/auth/auth_api.dart';
import 'package:front_end_flutter/domain/model/user_profile.dart';
import 'package:front_end_flutter/data/repository/profile_repository.dart';
import 'package:front_end_flutter/data/repository/schools_repository.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';

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

      UserProfile loaded;
      List<Map<String, dynamic>> available;
      if (OfflineRuntime.current?.uid == uid) {
        // The local data is already open: profile and institutions do not depend
        // on each other, so they are read together instead of one after the other.
        final both = await (_profiles.load(), _schools.load()).wait;
        loaded = both.$1;
        available = both.$2;
        if (!isCurrent()) return;
        if (loaded.role != 'docente') {
          profile = loaded;
          return;
        }
      } else {
        loaded = await _profiles.load();
        if (!isCurrent()) return;
        if (loaded.role != 'docente') {
          profile = loaded;
          return;
        }
        await OfflineRuntime.open(uid);
        if (!isCurrent()) return;
        // Once the local data is open, both reads come from it and can run together.
        final both = await (_profiles.load(), _schools.load()).wait;
        loaded = both.$1;
        available = both.$2;
        if (!isCurrent()) return;
      }

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
