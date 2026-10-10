import 'package:front_end_flutter/models/user_profile/user_profile.dart';
import 'package:front_end_flutter/services/profile_repository/profile_repository.dart';
import 'package:front_end_flutter/services/schools_repository/schools_repository.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';

class SessionViewModel extends SafeNotifier {
  SessionViewModel({ProfileRepository? profiles, SchoolsRepository? schools})
    : _profiles = profiles ?? ProfileRepository(),
      _schools = schools ?? SchoolsRepository();
  final ProfileRepository _profiles;
  final SchoolsRepository _schools;
  UserProfile? profile;
  List<Map<String, dynamic>> schools = [];
  bool loading = true;
  String? error;
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await _profiles.load();
      final available = await _schools.load();
      schools = available.where((school) {
        return profile!.schoolIds.contains(school['id']);
      }).toList();
      final UserProfile loadedProfile = profile!;
      profile = UserProfile(
        uid: loadedProfile.uid,
        name: loadedProfile.name,
        email: loadedProfile.email,
        role: loadedProfile.role,
        active: loadedProfile.active,
        schoolIds: schools.map((Map<String, dynamic> school) {
          return school['id'] as String;
        }).toList(),
      );
    } catch (_) {
      error = 'No pudimos cargar tu perfil e instituciones. Intenta de nuevo.';
    } finally {
      loading = false;
      notifyListeners();
    }
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
