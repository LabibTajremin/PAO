import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_core/pao_core.dart';

class _Plugin extends Mock implements FlutterLocalNotificationsPlugin;

class _Android extends Mock implements AndroidFlutterLocalNotificationsPlugin;

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const AndroidNotificationChannel('x', 'x'));
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
