// lib/data/auth/credential_rules.dart

/** Rules shared by login and registration, so both screens validate the same way. */
class CredentialRules {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /** The backend rejects shorter passwords with "weak-password". */
  static const int minPasswordLength = 6;

  /** Checks only the shape of the email; the backend decides if the account exists. */
  static bool isValidEmail(String email) {
    return _email.hasMatch(email.trim());
  }
}
