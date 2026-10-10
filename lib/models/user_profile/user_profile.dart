class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.schoolIds,
  });
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool active;
  final List<String> schoolIds;
  bool get canTeach {
    return active && role == 'docente' && schoolIds.isNotEmpty;
  }

  factory UserProfile.fromJson(String uid, Map<String, dynamic> data) {
    final ids = List<String>.from(data['schoolIds'] ?? []);
    if (ids.isEmpty && data['schoolId'] is String) {
      ids.add(data['schoolId'] as String);
    }
    return UserProfile(
      uid: uid,
      name: data['fullName'] as String? ?? 'Docente',
      email: data['email'] as String? ?? '',
      role: data['rol'] as String? ?? '',
      active: data['activo'] != false,
      schoolIds: List.unmodifiable(ids),
    );
  }
}
