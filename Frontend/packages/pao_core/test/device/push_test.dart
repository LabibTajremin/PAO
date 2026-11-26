import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_core/pao_core.dart';

class _Messaging extends Mock implements FirebaseMessaging;

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

  test('permission is undecided only before the first answer', () async {
    final m = _messaging();
    for (final (status, undecided, allowed) in [
      (AuthorizationStatus.notDetermined, true, false),
      (AuthorizationStatus.denied, false, false),
      (AuthorizationStatus.authorized, false, true),
      (AuthorizationStatus.provisional, false, true),
    ]) {
      when(m.getNotificationSettings).thenAnswer(
        (_) async => NotificationSettings(
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.disabled,
          authorizationStatus: status,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          timeSensitive: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          sound: AppleNotificationSetting.enabled,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
        ),
      );
      var opened = 0;
      final push = FcmPushService(
        m,
        openedApp: const Stream.empty(),
        settings: () async => ++opened > 0,
      );
      expect(await push.permissionUndecided(), undecided);
      expect(await push.allowed(), allowed);
      await push.openSettings();
      expect(opened, 1);
    }
    const off = NoPushService();
    expect(await off.permissionUndecided(), isFalse);
    expect(await off.allowed(), isTrue);
    await off.openSettings();
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
}
