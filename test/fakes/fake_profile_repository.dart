import 'package:front_end_flutter/models/user_profile/user_profile.dart';
import 'package:front_end_flutter/services/profile_repository/profile_repository.dart';

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository(this.profile);
  final UserProfile profile;
  @override
  Future<UserProfile> load() async {
    return profile;
  }
}
