import 'dart:async';

/// Runs the presence heartbeat while the provider is online.
///
/// Android throttles Dart timers once the app is in the background; a
/// foreground-service implementation of this interface keeps the beats going
/// there. [TimerHeartbeat] is the in-app one.
abstract interface class Heartbeat {
  /// Calls [beat] every [every] until [stop]; restarting replaces the old one.
  void start(Duration every, Future<void> Function() beat);

  /// Stops beating.
  void stop();
}

/// [Heartbeat] on a periodic timer.
class TimerHeartbeat implements Heartbeat {
  Timer? _timer;

  @override
  void start(Duration every, Future<void> Function() beat) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => unawaited(beat()));
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
