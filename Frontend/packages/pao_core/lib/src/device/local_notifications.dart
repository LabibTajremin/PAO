import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// An Android notification channel the apps create at start. The backend
/// picks one per notification type (`PushChannels`); all are high importance
/// because only those show as a heads-up banner.
class PushChannel {
  /// Creates a channel description.
  const PushChannel(this.id, this.name, this.description);

  /// The channel id the FCM payload names.
  final String id;

  /// The name shown in the phone's notification settings.
  final String name;

  /// The description shown under the name.
  final String description;
}

/// The channels, in the order the phone's settings list them.
const pushChannels = [
  PushChannel('pao_bookings', 'Bookings', 'New requests and booking updates'),
  PushChannel('pao_account', 'Account', 'Payments, dues and verification'),
  PushChannel('pao_general', 'General', 'News from PAO'),
];

/// Shows notifications from inside the app, which FCM does not do on Android
/// while the app is in the foreground.
abstract interface class LocalNotifier {
  /// Creates the channels and reports taps on shown notifications to
  /// [onTap], including the tap that launched the app.
  Future<void> start(void Function(Map<String, Object?> data) onTap);

  /// Shows a heads-up notification on [channel]; [data] comes back on tap.
  Future<void> show(
    int id,
    String? title,
    String? body,
    String channel,
    Map<String, Object?> data,
  );
}

/// [LocalNotifier] on flutter_local_notifications.
class PluginLocalNotifier implements LocalNotifier {
  /// Creates the notifier.
  PluginLocalNotifier(this._plugin);

  /// The notifier on the app's plugin instance.
  PluginLocalNotifier.system() : this(FlutterLocalNotificationsPlugin());

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> start(void Function(Map<String, Object?> data) onTap) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // FCM asks for permission after sign-in; asking here would prompt at
        // launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => onTap(decodePayload(r.payload)),
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final c in pushChannels) {
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          c.id,
          c.name,
          description: c.description,
          importance: Importance.high,
        ),
      );
    }
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
      onTap(decodePayload(response.payload));
    }
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    String channel,
    Map<String, Object?> data,
  ) => _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        channelName(channel),
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: jsonEncode(data),
  );
}

/// The display name of [id]; unknown ids use the general channel's name.
String channelName(String id) => pushChannels
    .firstWhere((c) => c.id == id, orElse: () => pushChannels.last)
    .name;

/// The data stored in a notification's payload; empty when there is none or
/// it is not a JSON object.
Map<String, Object?> decodePayload(String? payload) {
  if (payload == null || payload.isEmpty) return const {};
  final value = jsonDecode(payload);
  return value is Map<String, Object?> ? value : const {};
}
