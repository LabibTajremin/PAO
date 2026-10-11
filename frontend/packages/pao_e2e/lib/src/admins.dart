import 'package:dio/dio.dart';
import 'package:pao_e2e/src/client.dart';
import 'package:pao_e2e/src/totp.dart';

/// The Level 1 verification items a verifier approves.
const level1Items = [
  'nid',
  'selfie',
  'police_clearance',
  'address',
  'emergency_contact',
  'service_area',
  'code_of_conduct',
];

/// Admins' authenticator secrets. TOTP enrolment happens on an admin's first
/// sign-in only, so every process signing in to one stack must share them
/// (`test/e2e/.admins.env`, the file the API journeys use).
abstract interface class SecretStore {
  /// The secret of [email], if enrolled.
  Future<String?> read(String email);

  /// Remembers the secret [email] enrolled with.
  Future<void> write(String email, String secret);
}

/// Secrets kept for this process only.
class MemorySecrets implements SecretStore {
  /// Creates the store with [initial] secrets.
  MemorySecrets([Map<String, String> initial = const {}])
    : _secrets = {...initial};

  final Map<String, String> _secrets;

  @override
  Future<String?> read(String email) async => _secrets[email];

  @override
  Future<void> write(String email, String secret) async =>
      _secrets[email] = secret;
}

/// Signs seeded admins in with password and authenticator code, then acts for
/// them over HTTP.
class AdminDriver {
  /// Creates the driver; [now] and [wait] are for tests.
  AdminDriver(
    this._stack, {
    required this.password,
    required this.secrets,
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  final StackClient _stack;

  /// The seeded admins' password.
  final String password;

  /// Where authenticator secrets are kept.
  final SecretStore secrets;

  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;
  final _tokens = <String, ApiSession>{};

  /// Signs [email] in once per driver, enrolling TOTP on its first sign-in.
  Future<ApiSession> signIn(String email) async {
    if (_tokens[email] case final session?) return session;
    final challenge = await _stack.send(
      'POST',
      '/v1/auth/admin/login',
      body: {'email': email, 'password': password},
    );
    if (challenge['totpEnrolment'] case {'secret': final String secret}) {
      await secrets.write(email, secret);
    }
    final secret = await secrets.read(email);
    if (secret == null) throw StackError('no TOTP secret for $email');
    final id = '${challenge['challengeId']}';
    var res = await _totp(id, secret);
    if (res.statusCode != 200) {
      // A code is accepted once; a sign-in right after another waits for the
      // next one.
      await _wait(nextTotpWindow(_now()).difference(_now()));
      res = await _totp(id, secret);
    }
    final body = res.data;
    if (res.statusCode != 200 || body is! Json) {
      throw StackError('admin $email TOTP: ${res.statusCode} $body');
    }
    return _tokens[email] = ApiSession(
      id: email,
      token: '${body['accessToken']}',
    );
  }

  Future<Response<Object?>> _totp(String challengeId, String secret) =>
      _stack.call(
        'POST',
        '/v1/auth/admin/totp',
        body: {'challengeId': challengeId, 'code': totp(secret, _now())},
      );

  /// Has the seeded verifier approve [items] of [providerId]'s submission,
  /// once the worker has relayed it and they all wait for review.
  Future<void> approve(
    String providerId, [
    List<String> items = level1Items,
  ]) async {
    final verifier = await signIn('verifier@pao.bd');
    final path = '/v1/admin/verifications/$providerId';
    await eventually('items of $providerId pending review', () async {
      final review = await _stack.send('GET', path, as: verifier);
      final pending = {
        for (final item in review['items']! as List<Object?>)
          if (item case {'type': final String type, 'status': 'pending'}) type,
      };
      return pending.containsAll(items);
    });
    for (final item in items) {
      await _stack.send('POST', '$path/items/$item/approve', as: verifier);
    }
  }
}
