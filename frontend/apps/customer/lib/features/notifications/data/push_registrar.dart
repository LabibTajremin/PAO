import 'dart:async';

import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/notifications/domain/notifications_repository.dart';
import 'package:pao_customer/features/notifications/domain/push_route.dart';

/// Registers the device for push while signed in and turns tapped
/// notifications into app locations (C-13).
class PushRegistrar {
  /// Creates the registrar; `open` navigates to a location.
  PushRegistrar({
    required this._sessions,
    required this._push,
    required this._repo,
    required this._open,
  });

  final SessionManager _sessions;
  final PushService _push;
  final NotificationsRepository _repo;
  final void Function(String location) _open;
  final _subs = <StreamSubscription<Object?>>[];
  bool _registered = false;

  /// Starts listening to the session, token refreshes and taps.
  void start() {
    _sessions.addListener(_onSession);
    _subs
      ..add(_push.tokenRefresh.listen(_register))
      ..add(_push.opened.listen((data) => _open(pushRoute(data))));
    _onSession();
  }

  // Registers once per sign-in; a failed attempt waits for the next sign-in
  // or token refresh, since the inbox keeps every message anyway.
  void _onSession() {
    if (!_sessions.signedIn) {
      _registered = false;
      return;
    }
    if (_registered) return;
    _registered = true;
    unawaited(_registerCurrent());
  }

  Future<void> _registerCurrent() async {
    final token = await _push.token();
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    if (!_sessions.signedIn) return;
    await attempt(() => _repo.registerDevice(token));
  }

  /// Stops listening.
  Future<void> stop() async {
    _sessions.removeListener(_onSession);
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }
}
