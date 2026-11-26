import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pao_core/src/device/local_notifications.dart';

/// Push notifications: the device token to register and the data of tapped
/// notifications, used to open the right screen.
abstract interface class PushService {
  /// Prepares the device so notifications pop up as banners, also while the
  /// app is open. Call once at start, before listening to [opened].
  Future<void> start();

  /// Whether the user has not yet answered the notification permission
  /// prompt, so the app can explain before [token] asks.
  Future<bool> permissionUndecided();

  /// Whether the phone lets PAO show notifications.
  Future<bool> allowed();

  /// Opens the phone's settings for this app, where notifications can be
  /// turned back on.
  Future<void> openSettings();

  /// The FCM token, after asking permission; null when unavailable.
  Future<String?> token();

  /// New tokens issued by FCM.
  Stream<String> get tokenRefresh;

  /// Data of notifications the user tapped, including the one that launched
  /// the app. Listen once.
  Stream<Map<String, Object?>> get opened;
}

/// [PushService] on Firebase Cloud Messaging.
class FcmPushService implements PushService {
  /// Creates the service. The streams default to FirebaseMessaging's; with a
  /// `local` notifier, foreground messages are shown through it, which
  /// Android needs (`showForeground`) and iOS does not, since there FCM shows
  /// them once the presentation options are set.
  FcmPushService(
    this._messaging, {
    Stream<RemoteMessage>? openedApp,
    Stream<RemoteMessage>? foreground,
    this._local,
    this._showForeground = false,
    Future<bool> Function()? settings,
  }) : _settings = settings ?? Geolocator.openAppSettings,
       _openedApp = openedApp ?? FirebaseMessaging.onMessageOpenedApp,
       _foreground = foreground ?? FirebaseMessaging.onMessage;

  final FirebaseMessaging _messaging;
  final Future<bool> Function() _settings;
  final Stream<RemoteMessage> _openedApp;
  final Stream<RemoteMessage> _foreground;
  final LocalNotifier? _local;
  final bool _showForeground;
  // Not broadcast: a tap that launches the app arrives before anyone listens.
  final _taps = StreamController<Map<String, Object?>>();

  @override
  Future<void> start() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final local = _local;
    if (local == null) return;
    await local.start(_taps.add);
    if (_showForeground) _foreground.listen((m) => unawaited(_show(local, m)));
  }

  Future<void> _show(LocalNotifier local, RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    await local.show(
      (m.messageId ?? '${n.title}${n.body}').hashCode,
      n.title,
      n.body,
      n.android?.channelId ?? pushChannels.first.id,
      m.data,
    );
  }

  @override
  Future<bool> permissionUndecided() async =>
      (await _messaging.getNotificationSettings()).authorizationStatus ==
      AuthorizationStatus.notDetermined;

  @override
  Future<bool> allowed() async => switch ((await _messaging
          .getNotificationSettings())
      .authorizationStatus) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
    _ => false,
  };

  @override
  Future<void> openSettings() => _settings();

  @override
  Future<String?> token() async {
    await _messaging.requestPermission();
    return await _messaging.getToken();
  }

  @override
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, Object?>> get opened async* {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) yield initial.data;
    final sub = _openedApp.listen((m) => _taps.add(m.data));
    try {
      yield* _taps.stream;
    } finally {
      await sub.cancel();
    }
  }
}

/// Used when Firebase is not configured (local development and tests).
class NoPushService implements PushService {
  /// Creates the service.
  const NoPushService();

  @override
  Future<void> start() async {}

  @override
  Future<bool> permissionUndecided() async => false;

  @override
  Future<bool> allowed() async => true;

  @override
  Future<void> openSettings() async {}

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, Object?>> get opened => const Stream.empty();
}
