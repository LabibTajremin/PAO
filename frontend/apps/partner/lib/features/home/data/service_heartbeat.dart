import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pao_partner/features/home/domain/heartbeat.dart';

/// What Android's ongoing notification says while the provider is online.
typedef OnlineNotice = ({String title, String body});

/// The channel to `PresenceService.kt` in the Android app.
const presenceChannel = MethodChannel('pao/presence_service');

/// [Heartbeat] that keeps an Android foreground service running while the
/// provider is online (ADR-0028).
///
/// The beats still come from [_inner] in Dart. The service only holds the
/// process in the foreground, so Android neither freezes the timer nor
/// withholds location once the app is in the background.
class ServiceHeartbeat implements Heartbeat {
  /// Wraps [_inner]; [android] defaults to the platform the app runs on.
  ServiceHeartbeat(
    this._inner,
    this._notice, {
    MethodChannel channel = presenceChannel,
    bool? android,
  }) : _channel = channel,
       _android = android ?? defaultTargetPlatform == TargetPlatform.android;

  final Heartbeat _inner;
  final OnlineNotice _notice;
  final MethodChannel _channel;
  final bool _android;

  @override
  void start(Duration every, Future<void> Function() beat) {
    _inner.start(every, beat);
    _call('start', {'title': _notice.title, 'body': _notice.body});
  }

  @override
  void stop() {
    _inner.stop();
    _call('stop');
  }

  // A refused service (Android blocks starting one from the background) still
  // leaves the timer beating while the app is open; the server's presence
  // expiry then takes a backgrounded provider offline, which fails safe.
  void _call(String method, [Map<String, String>? args]) {
    if (!_android) return;
    _channel.invokeMethod<void>(method, args).ignore();
  }
}
