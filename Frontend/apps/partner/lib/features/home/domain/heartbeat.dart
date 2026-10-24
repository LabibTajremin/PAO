import 'dart:async';

/// Runs the presence heartbeat while the provider is online.
///
/// Android freezes background apps and their Dart timers; the data layer's
/// `ServiceHeartbeat` wraps [TimerHeartbeat] with a foreground service that
/// keeps the beats going there.
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
