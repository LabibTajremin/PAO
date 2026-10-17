import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens for one signed-in account. The admin web app has no [refreshToken]:
/// it lives in an HttpOnly cookie the browser sends.
@immutable
class Session {
  /// Creates a session.
  const Session({required this.accessToken, this.refreshToken});

  /// Short-lived bearer token.
  final String accessToken;

  /// Long-lived rotating token, mobile apps only.
  final String? refreshToken;
}

/// Persists the session between launches.
abstract interface class SessionStore {
  /// Returns the saved session, if any.
  Future<Session?> read();

  /// Saves [session], replacing any previous one.
  Future<void> write(Session session);

  /// Forgets the session.
  Future<void> delete();
}

/// Keeps the session in memory; used on the web, where the cookie survives
/// reloads.
class MemorySessionStore implements SessionStore {
  Session? _session;

  @override
  Future<Session?> read() async => _session;

  @override
  Future<void> write(Session session) async => _session = session;

  @override
  Future<void> delete() async => _session = null;
}

/// Keeps the session in the Keystore/Keychain on mobile.
class SecureSessionStore implements SessionStore {
  /// Creates the store over [storage].
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _access = 'pao.access';
  static const _refresh = 'pao.refresh';

  @override
  Future<Session?> read() async {
    final access = await _storage.read(key: _access);
    if (access == null) return null;
    return Session(
      accessToken: access,
      refreshToken: await _storage.read(key: _refresh),
    );
  }

  @override
  Future<void> write(Session session) async {
    await _storage.write(key: _access, value: session.accessToken);
    await _storage.write(key: _refresh, value: session.refreshToken);
  }

  @override
  Future<void> delete() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}

/// The current session for the whole app; routers listen to it.
class SessionManager extends ChangeNotifier {
  /// Creates a manager backed by a session store.
  SessionManager(this._store);

  final SessionStore _store;
  Session? _session;
  bool _expired = false;

  /// The signed-in session, if any.
  Session? get session => _session;

  /// Whether someone is signed in.
  bool get signedIn => _session != null;

  /// Whether the last sign-out happened because the session expired (C63).
  bool get expired => _expired;

  /// Loads the saved session at start-up.
  Future<void> restore() async {
    _session = await _store.read();
    notifyListeners();
  }

  /// Stores a new or refreshed session.
  Future<void> signIn(Session session) async {
    await _store.write(session);
    _session = session;
    _expired = false;
    notifyListeners();
  }

  /// Forgets the session; [expired] sends the user to the welcome-back screen.
  Future<void> signOut({bool expired = false}) async {
    await _store.delete();
    _session = null;
    _expired = expired;
    notifyListeners();
  }
}
