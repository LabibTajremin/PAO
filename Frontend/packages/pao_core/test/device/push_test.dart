import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_core/pao_core.dart';

class _Messaging extends Mock implements FirebaseMessaging;

class _Plugin extends Mock implements FlutterLocalNotificationsPlugin;

class _Android extends Mock implements AndroidFlutterLocalNotificationsPlugin;

class _Local implements LocalNotifier {
  void Function(Map<String, Object?>)? onTap;
  final shown = <(int, String?, String, Map<String, Object?>)>[];

  @override
  Future<void> start(void Function(Map<String, Object?>) onTap) async =>
      this.onTap = onTap;

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    String channel,
    Map<String, Object?> data,
  ) async => shown.add((id, title, channel, data));
}

_Messaging _messaging() {
  final m = _Messaging();
  when(
    () => m.setForegroundNotificationPresentationOptions(
      alert: any(named: 'alert'),
      badge: any(named: 'badge'),
      sound: any(named: 'sound'),
    ),
  ).thenAnswer((_) async {});
  when(m.getInitialMessage).thenAnswer((_) async => null);
  return m;
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const AndroidNotificationChannel('x', 'x'));
  });

  test('start sets iOS foreground banners and shows Android foreground '
      'messages on their channel', () async {
    final m = _messaging();
    final local = _Local();
    final foreground = StreamController<RemoteMessage>();
    final push = FcmPushService(
      m,
      openedApp: const Stream.empty(),
      foreground: foreground.stream,
      local: local,
      showForeground: true,
    );
    await push.start();
    verify(
      () => m.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      ),
    ).called(1);
    foreground
      ..add(
        const RemoteMessage(
          messageId: 'm1',
          notification: RemoteNotification(
            title: 'New booking request',
            android: AndroidNotification(channelId: 'pao_account'),
          ),
          data: {'type': 'payment_confirmed'},
        ),
      )
      ..add(const RemoteMessage(notification: RemoteNotification(title: 't')))
      ..add(const RemoteMessage(data: {'silent': '1'}));
    await _flush();
    expect(local.shown.map((s) => (s.$2, s.$3)), [
      ('New booking request', 'pao_account'),
      ('t', 'pao_bookings'),
    ]);
    expect(local.shown.first.$1, 'm1'.hashCode);
    expect(local.shown.first.$4, {'type': 'payment_confirmed'});
  });

  test('local taps, the launch tap and FCM taps all reach opened', () async {
    final m = _messaging();
    when(m.getInitialMessage).thenAnswer(
      (_) async => const RemoteMessage(data: {'bookingId': 'launch'}),
    );
    final local = _Local();
    final openedApp = StreamController<RemoteMessage>();
    final push = FcmPushService(
      m,
      openedApp: openedApp.stream,
      foreground: const Stream.empty(),
      local: local,
    );
    await push.start();
    local.onTap!({'bookingId': 'early'});
    final got = <Object?>[];
    final sub = push.opened.listen((d) => got.add(d['bookingId']));
    await _flush();
    openedApp.add(const RemoteMessage(data: {'bookingId': 'fcm'}));
    await _flush();
    local.onTap!({'bookingId': 'local'});
    await _flush();
    expect(got, ['launch', 'early', 'fcm', 'local']);
    await sub.cancel();
  });

  test('without a local notifier start only sets the iOS options', () async {
    final m = _messaging();
    await FcmPushService(m, openedApp: const Stream.empty()).start();
    verify(
      () => m.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      ),
    ).called(1);
  });

  group('PluginLocalNotifier', () {
    late _Plugin plugin;
    late _Android android;
    DidReceiveNotificationResponseCallback? onResponse;

    setUp(() {
      plugin = _Plugin();
      android = _Android();
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((i) async {
        onResponse =
            i.namedArguments[#onDidReceiveNotificationResponse]
                as DidReceiveNotificationResponseCallback?;
        return true;
      });
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(() => android.createNotificationChannel(any()))
          .thenAnswer((_) async {});
      when(plugin.getNotificationAppLaunchDetails).thenAnswer(
        (_) async => const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: '{"bookingId":"b1"}',
          ),
        ),
      );
    });

    test('creates the three high-importance channels and reports taps, '
        'including the launch tap', () async {
      final taps = <Map<String, Object?>>[];
      await PluginLocalNotifier(plugin).start(taps.add);
      final channels = verify(
        () => android.createNotificationChannel(captureAny()),
      ).captured.cast<AndroidNotificationChannel>();
      expect(channels.map((c) => c.id), [
        'pao_bookings',
        'pao_account',
        'pao_general',
      ]);
      expect(channels.every((c) => c.importance == Importance.high), isTrue);
      onResponse!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '{"type":"booking_started"}',
        ),
      );
      expect(taps, [
        {'bookingId': 'b1'},
        {'type': 'booking_started'},
      ]);
    });

    test('a launch that was not from a notification reports nothing, and '
        'a missing Android plugin is fine', () async {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);
      when(plugin.getNotificationAppLaunchDetails)
          .thenAnswer((_) async => const NotificationAppLaunchDetails(false));
      final taps = <Map<String, Object?>>[];
      await PluginLocalNotifier(plugin).start(taps.add);
      when(plugin.getNotificationAppLaunchDetails)
          .thenAnswer((_) async => const NotificationAppLaunchDetails(true));
      await PluginLocalNotifier(plugin).start(taps.add);
      when(plugin.getNotificationAppLaunchDetails)
          .thenAnswer((_) async => null);
      await PluginLocalNotifier(plugin).start(taps.add);
      expect(taps, isEmpty);
      verifyNever(() => android.createNotificationChannel(any()));
    });

    test('show posts a high-priority notification with the data', () async {
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      await PluginLocalNotifier(plugin)
          .show(7, 'T', 'B', 'pao_account', {'type': 'x'});
      final details =
          verify(
                () => plugin.show(
                  id: 7,
                  title: 'T',
                  body: 'B',
                  notificationDetails: captureAny(named: 'notificationDetails'),
                  payload: '{"type":"x"}',
                ),
              ).captured.single
              as NotificationDetails;
      expect(details.android!.channelId, 'pao_account');
      expect(details.android!.channelName, 'Account');
      expect(details.android!.importance, Importance.high);
      expect(details.android!.priority, Priority.high);
    });
  });

  test('channel names and payload decoding', () {
    expect(channelName('pao_bookings'), 'Bookings');
    expect(channelName('nope'), 'General');
    expect(decodePayload(null), isEmpty);
    expect(decodePayload(''), isEmpty);
    expect(decodePayload('[1]'), isEmpty);
    expect(decodePayload('{"a":1}'), {'a': 1});
    expect(PluginLocalNotifier.system(), isA<LocalNotifier>());
  });
}
