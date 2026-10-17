import 'package:firebase_messaging/firebase_messaging.dart';

/// Push notifications: the device token to register and the data of tapped
/// notifications, used to open the right screen.
abstract interface class PushService {
  /// The FCM token, after asking permission; null when unavailable.
  Future<String?> token();

  /// New tokens issued by FCM.
  Stream<String> get tokenRefresh;

  /// Data of notifications the user tapped, including the one that launched
  /// the app.
  Stream<Map<String, Object?>> get opened;
}

/// [PushService] on Firebase Cloud Messaging.
class FcmPushService implements PushService {
  /// Creates the service; [openedApp] defaults to FirebaseMessaging's stream.
  FcmPushService(this._messaging, {Stream<RemoteMessage>? openedApp})
    : _openedApp = openedApp ?? FirebaseMessaging.onMessageOpenedApp;

  final FirebaseMessaging _messaging;
  final Stream<RemoteMessage> _openedApp;

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
    yield* _openedApp.map((m) => m.data);
  }
}

/// Used when Firebase is not configured (local development and tests).
class NoPushService implements PushService {
  /// Creates the service.
  const NoPushService();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, Object?>> get opened => const Stream.empty();
}
