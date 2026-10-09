import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  late SessionManager sessions;
  late PermissionService permissions;
  late RouteGuard guard;

  setUp(() async {
    final dio = Dio();
    DioAdapter(dio: dio).onGet(
      '/v1/me/permissions',
      (s) => s.reply(200, {
        'roles': <String>[],
        'permissions': <String>[],
        'screens': ['C07'],
      }),
    );
    sessions = SessionManager(MemorySessionStore());
    permissions = PermissionService(dio);
    await permissions.load();
    guard = RouteGuard(
      sessions: sessions,
      permissions: permissions,
      paths: GuardPaths(
        home: '/home',
        signIn: ['/auth'].first,
        expired: '/welcome-back',
        denied: '/denied',
      ),
      screens: {'/home': 'C07', '/bookings/:id': 'C19', '/denied': 'X'},
      public: {'/auth', '/onboarding'},
    );
  });

  test('signed-out users reach only public routes', () async {
    expect(guard.redirect('/auth?from=x'), isNull);
    expect(guard.redirect('/home'), '/auth');
    await sessions.signOut(expired: true);
    expect(guard.redirect('/home'), '/welcome-back');
  });

  test('signed-in users need the screen', () async {
    await sessions.signIn(const Session(accessToken: 'a'));
    expect(guard.redirect('/home'), isNull);
    expect(guard.redirect('/bookings/42'), '/denied');
    expect(guard.redirect('/bookings/42/receipt'), isNull);
    expect(guard.redirect('/denied'), isNull);
    expect(guard.redirect('/auth'), '/home');
    expect(guard.redirect('/welcome-back'), '/home');
    expect(
      RouteGuard(
        sessions: sessions,
        permissions: permissions,
        paths: guard.paths,
      ).redirect('/x'),
      isNull,
    );
  });

  test('route patterns', () {
    expect(routeMatches('/a/:id', '/a/1'), isTrue);
    expect(routeMatches('/a/:id', '/b/1'), isFalse);
    expect(routeMatches('/a', '/a/1'), isFalse);
  });

  test('verification gate', () {
    const allowed = {'/enrol/:step', '/verification'};
    expect(
      verificationGate(
        cleared: true,
        location: '/jobs',
        allowed: allowed,
        gate: '/verification',
      ),
      isNull,
    );
    expect(
      verificationGate(
        cleared: false,
        location: '/enrol/nid',
        allowed: allowed,
        gate: '/verification',
      ),
      isNull,
    );
    expect(
      verificationGate(
        cleared: false,
        location: '/jobs?x=1',
        allowed: allowed,
        gate: '/verification',
      ),
      '/verification',
    );
  });
}
