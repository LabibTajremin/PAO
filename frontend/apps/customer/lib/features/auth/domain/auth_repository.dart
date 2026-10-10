/// A one-time code was sent (C-01).
class CodeSent {
  /// Creates the result.
  const CodeSent({required this.resendAfter});

  /// Wait before another code may be requested.
  final Duration resendAfter;
}

/// Tokens from a successful sign-in.
class SignedIn {
  /// Creates the result.
  const SignedIn({required this.accessToken, this.refreshToken});

  /// Bearer token.
  final String accessToken;

  /// Rotating refresh token.
  final String? refreshToken;
}

/// Phone sign-in by one-time code.
abstract interface class AuthRepository {
  /// Sends a code to [phone].
  Future<CodeSent> requestCode(String phone);

  /// Checks [code] and signs the customer in.
  Future<SignedIn> verify(String phone, String code);
}

/// Normalises Bangladeshi mobile numbers to `01XXXXXXXXX`; null when invalid.
String? normalisePhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('880')) digits = digits.substring(2);
  if (digits.length == 10 && digits.startsWith('1')) digits = '0$digits';
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(digits) ? digits : null;
}
