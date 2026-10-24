/// The first login step was accepted (A-01).
class LoginChallenge {
  /// Creates the challenge.
  const LoginChallenge({
    required this.id,
    this.enrolSecret,
    this.enrolUrl,
    this.mustChangePassword = false,
  });

  /// Challenge to answer with the authenticator code.
  final String id;

  /// On the first login, the key to add to an authenticator app.
  final String? enrolSecret;

  /// The same key as an `otpauth://` link.
  final String? enrolUrl;

  /// The admin still has the temporary password from the invite.
  final bool mustChangePassword;
}

/// Admin sign-in: password, then a TOTP code.
abstract interface class AdminAuthRepository {
  /// Checks [email] and [password].
  Future<LoginChallenge> login(String email, String password);

  /// Answers [challengeId] with [code]; returns the access token.
  Future<String> verify(String challengeId, String code);

  /// Replaces [current] with [next].
  Future<void> changePassword(String current, String next);
}

/// Shortest password the API accepts as a new one.
const minPasswordLength = 12;
