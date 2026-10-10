import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_admin/app/app.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Every admin screen, for a super admin.
final List<String> allScreens = [
  for (var i = 1; i <= 12; i++) 'A${'$i'.padLeft(2, '0')}',
];

/// An API error body.
Map<String, Object?> apiError(String code) => {
  'error': {'code': code, 'message': 'x'},
};

/// A desktop-sized window, where the menu is a sidebar.
void desktop(WidgetTester tester) => _size(tester, const Size(1280, 900));

/// A narrow window, where the menu is a drawer.
void narrow(WidgetTester tester) => _size(tester, const Size(800, 900));

void _size(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Services over a mocked API, with helpers to sign in.
class Harness {
  /// Builds the harness; [now] fixes the clock.
  factory Harness.create({DateTime? now}) {
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
    final services = AppServices(
      sessions: SessionManager(MemorySessionStore()),
      permissions: PermissionService(dio),
      locale: LocaleController(PaoLocales.english),
      api: dio,
      clock: () => now ?? DateTime.utc(2026, 10, 9, 4),
    );
    return Harness._(services, http, sent);
  }
  Harness._(this.services, this.http, this.sent);

  /// App services under test.
  final AppServices services;

  /// The mocked API; register replies with `http.onGet(...)`.
  final DioAdapter http;

  /// Every request sent, to assert bodies.
  final List<RequestOptions> sent;

  /// The JSON body of the last request to [path].
  Object? bodyOf(String path) {
    final data = sent.lastWhere((o) => o.path == path).data;
    return data is String ? jsonDecode(data) : data;
  }

  /// Replies to the permissions call with [screens].
  void permits(List<String> screens, {List<String> roles = const []}) =>
      http.onGet(
        '/v1/me/permissions',
        (s) => s.reply(200, {
          'roles': roles,
          'permissions': <String>[],
          'screens': screens,
        }),
      );

  /// Signs in with [screens], loading permissions in real async.
  Future<void> signIn(WidgetTester tester, {List<String>? screens}) async {
    permits(screens ?? allScreens, roles: ['super_admin']);
    await services.sessions.signIn(const Session(accessToken: 'a'));
    await tester.runAsync(services.permissions.load);
  }

  /// Pumps the whole app at [location].
  Future<void> pumpApp(
    WidgetTester tester, [
    String location = Routes.dashboard,
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
    localizationsDelegates: adminDelegates,
    home: page,
  ),
);
