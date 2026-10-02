class AuthTokenStore {
  static final AuthTokenStore _instance = AuthTokenStore._();
  factory AuthTokenStore() => _instance;
  AuthTokenStore._();

  String? _token;
  String? _uid;

  String? get token => _token;
  String? get uid => _uid;

  void save({required String token, required String uid}) {
    _token = token;
    _uid = uid;
  }

  void clear() {
    _token = null;
    _uid = null;
  }

  Map<String, String> get authHeaders {
    if (_token == null) return {};
    return {'Authorization': 'Bearer $_token'};
  }
}
