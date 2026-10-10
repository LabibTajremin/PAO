import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/app.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/location/domain/places.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fixed GPS fix in Banani.
class FakeLocation implements LocationService {
  /// What [current] returns; null means location is off.
  GeoPoint? point = const GeoPoint(23.794, 90.407);

  @override
  Future<GeoPoint?> current() async => point;
}

/// Push service the test drives.
class FakePush implements PushService {
  /// Token returned by [token].
  String? value = 'device-token';

  /// Refreshed tokens.
  final refreshes = StreamController<String>.broadcast();

  /// Tapped notifications.
  final taps = StreamController<Map<String, Object?>>.broadcast();

  @override
  Future<String?> token() async => value;

  @override
  Stream<String> get tokenRefresh => refreshes.stream;

  @override
  Stream<Map<String, Object?>> get opened => taps.stream;
}

/// Camera stand-in.
class FakePicker extends Mock implements ImagePicker;

/// Every customer screen, for an account allowed everywhere.
final List<String> allScreens = [
  for (var i = 1; i <= 64; i++) 'C${'$i'.padLeft(2, '0')}',
  'C13b',
  'C18b',
];

/// The smallest valid PNG, for photo pickers.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGA'
  'WjR9awAAAABJRU5ErkJggg==',
);

/// Gives the test a phone-width screen tall enough that whole pages build.
void tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// An API error body.
Map<String, Object?> apiError(String code) => {
  'error': {'code': code, 'message': 'x'},
};

/// A saved customer profile.
Map<String, Object?> profile({String name = 'Nusrat Jahan'}) => {
  'id': 'c0000000-0000-4000-8000-000000000001',
  'name': name,
  'phone': '+8801712345678',
  'language': 'en',
};

/// Services over a mocked API, with helpers to sign in.
class Harness {
  Harness._(this.services, this.http, this.launched, this.picker, this.sent);

  /// App services under test.
  final AppServices services;

  /// The mocked API; register replies with `http.onGet(...)`.
  final DioAdapter http;

  /// URIs handed to other apps.
  final List<Uri> launched;

  /// The camera.
  final FakePicker picker;

  /// Every request sent, to assert bodies.
  final List<RequestOptions> sent;

  /// The JSON body of the last request to [path].
  Object? bodyOf(String path) {
    final data = sent.lastWhere((o) => o.path == path).data;
    return data is String ? jsonDecode(data) : data;
  }

  /// Push stand-in.
  FakePush get push => services.push as FakePush;

  /// Location stand-in.
  FakeLocation get location => services.location as FakeLocation;

  /// Builds the harness; [now] fixes the clock and [places] answers address
  /// searches.
  static Future<Harness> create({
    DateTime? now,
    PlacesService places = const NoPlacesService(),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'));
    final http = DioAdapter(
      dio: dio,
      matcher: const UrlRequestMatcher(matchMethod: true),
    );
    final sent = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, handler) {
          sent.add(o);
          handler.next(o);
        },
      ),
    );
    final launched = <Uri>[];
    final picker = FakePicker();
    final services = AppServices(
      sessions: SessionManager(MemorySessionStore()),
      permissions: PermissionService(dio),
      locale: LocaleController(PaoLocales.english),
      api: dio,
      prefs: await Prefs.open(),
      online: ValueNotifier(true),
      location: FakeLocation(),
      launcher: Launcher(
        open: (u) async {
          launched.add(u);
          return true;
        },
      ),
      photos: PhotoSource(picker),
      push: FakePush(),
      places: places,
      clock: () => now ?? DateTime.utc(2026, 10, 9, 4),
    );
    return Harness._(services, http, launched, picker, sent);
  }

  /// Signs in with [screens], loading permissions and the gate in real async;
  /// a [newAccount] has no profile yet.
  Future<void> signIn(
    WidgetTester tester, {
    List<String>? screens,
    bool newAccount = false,
  }) async {
    http
      ..onGet(
        '/v1/me/permissions',
        (s) => s.reply(200, {
          'roles': ['customer'],
          'permissions': <String>[],
          'screens': screens ?? allScreens,
        }),
      )
      ..onGet(
        '/v1/customer/profile',
        (s) => newAccount
            ? s.reply(404, apiError('NOT_FOUND'))
            : s.reply(200, profile()),
      );
    await services.sessions.signIn(const Session(accessToken: 'a'));
    await tester.runAsync(() async {
      await services.permissions.load();
      await services.gate.load();
    });
  }

  /// Pumps the whole app at [location].
  Future<void> pumpApp(
    WidgetTester tester, [
    String location = Routes.home,
  ]) async {
    await tester.pumpWidget(PaoApp(services: services, initial: location));
    await settle(tester);
  }

  /// Lets mocked HTTP replies arrive, then settles the frames.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }

  /// Navigates the running app.
  Future<void> go(WidgetTester tester, String location) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
    await settle(tester);
  }
}

/// Pumps [page] alone, themed and localised, without a router.
Future<void> pumpPage(WidgetTester tester, Widget page) => tester.pumpWidget(
  MaterialApp(
    theme: PaoTheme.light(),
    locale: const Locale('en'),
    supportedLocales: PaoLocales.all,
    localizationsDelegates: customerDelegates,
    home: page,
  ),
);
