import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_core/pao_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _Gps extends Mock implements GeolocatorPlatform;

class _Picker extends Mock implements ImagePicker;

class _Messaging extends Mock implements FirebaseMessaging;

class _Urls extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final opened = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return true;
  }
}

Position _at(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(CameraDevice.rear);
  });

  group('location', () {
    late _Gps gps;
    setUp(() {
      gps = _Gps();
      when(gps.isLocationServiceEnabled).thenAnswer((_) async => true);
      when(
        () => gps.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => _at(23.79, 90.4));
    });

    test('returns the fix once permission is granted', () async {
      when(gps.checkPermission)
          .thenAnswer((_) async => LocationPermission.denied);
      when(gps.requestPermission)
          .thenAnswer((_) async => LocationPermission.whileInUse);
      final p = await DeviceLocationService(gps).current();
      expect([p!.lat, p.lng], [23.79, 90.4]);
    });

    test('null when refused or switched off', () async {
      when(gps.checkPermission)
          .thenAnswer((_) async => LocationPermission.deniedForever);
      expect(await DeviceLocationService(gps).current(), isNull);
      when(gps.checkPermission)
          .thenAnswer((_) async => LocationPermission.denied);
      when(gps.requestPermission)
          .thenAnswer((_) async => LocationPermission.denied);
      expect(await DeviceLocationService(gps).current(), isNull);
      when(gps.isLocationServiceEnabled).thenAnswer((_) async => false);
      expect(await DeviceLocationService(gps).current(), isNull);
      expect(DeviceLocationService(), isA<LocationService>());
    });
  });

  test('launcher opens directions and the dialler', () async {
    final urls = _Urls();
    UrlLauncherPlatform.instance = urls;
    final l = Launcher();
    expect(await l.directions(23.7, 90.4), isTrue);
    expect(await l.call('+8801712345678'), isTrue);
    expect(urls.opened, [
      'https://www.google.com/maps/dir/?api=1&destination=23.7%2C90.4',
      'tel:+8801712345678',
    ]);
  });

  test('photos are compressed, cancelled captures return null', () async {
    final picker = _Picker();
    final png = img.encodePng(img.Image(width: 3000, height: 1000));
    when(
      () => picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: any(named: 'preferredCameraDevice'),
      ),
    ).thenAnswer((_) async => XFile.fromData(png));
    when(() => picker.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => null);
    final photo = await PhotoSource(picker).capture(selfie: true);
    expect(img.decodeJpg(photo!)!.width, 1600);
    expect(await PhotoSource(picker).pick(), isNull);
    when(() => picker.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => XFile.fromData(png));
    expect(await PhotoSource(picker).pick(), isA<Uint8List>());
    when(
      () => picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: any(named: 'preferredCameraDevice'),
      ),
    ).thenAnswer((_) async => null);
    expect(await PhotoSource(picker).capture(), isNull);
    expect(PhotoSource(), isNotNull);
  });

  test('prefs keep strings and flags', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await Prefs.open();
    expect(
      [prefs.string(Prefs.languageKey), prefs.flag(Prefs.onboardedKey)],
      [null, false],
    );
    await prefs.setString(Prefs.languageKey, 'en');
    await prefs.setFlag(Prefs.onboardedKey, value: true);
    expect(
      [prefs.string(Prefs.languageKey), prefs.flag(Prefs.onboardedKey)],
      ['en', true],
    );
  });

  test('FCM token, refreshes and opened notifications', () async {
    final m = _Messaging();
    final opened = StreamController<RemoteMessage>();
    when(m.requestPermission).thenAnswer(
      (_) async => const NotificationSettings(
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.disabled,
        authorizationStatus: AuthorizationStatus.authorized,
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
    when(m.getToken).thenAnswer((_) async => 'tok');
    when(() => m.onTokenRefresh).thenAnswer((_) => Stream.value('tok2'));
    when(m.getInitialMessage)
        .thenAnswer((_) async => const RemoteMessage(data: {'bookingId': '1'}));
    final push = FcmPushService(m, openedApp: opened.stream);
    expect(await push.token(), 'tok');
    expect(await push.tokenRefresh.first, 'tok2');
    final got = <Map<String, Object?>>[];
    final sub = push.opened.listen(got.add);
    await Future<void>.delayed(Duration.zero);
    opened.add(const RemoteMessage(data: {'bookingId': '2'}));
    await Future<void>.delayed(Duration.zero);
    expect(got.map((d) => d['bookingId']), ['1', '2']);
    await sub.cancel();
    when(m.getInitialMessage).thenAnswer((_) async => null);
    expect(
      await FcmPushService(m, openedApp: const Stream.empty()).opened.toList(),
      isEmpty,
    );
    expect(FcmPushService(m), isA<PushService>());
    const make = NoPushService.new;
    final none = make();
    expect(await none.token(), isNull);
    expect(await none.tokenRefresh.isEmpty, isTrue);
    expect(await none.opened.isEmpty, isTrue);
  });
}
