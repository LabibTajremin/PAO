import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_core/pao_core.dart';

void main() {
  testWidgets('redirects follow sign-in and sign-out', (tester) async {
    final dio = Dio();
    DioAdapter(dio: dio).onGet(
      '/v1/me/permissions',
      (s) => s.reply(200, {
        'roles': ['customer'],
        'permissions': <String>[],
        'screens': ['C07'],
      }),
    );
    final sessions = SessionManager(MemorySessionStore());
    final permissions = PermissionService(dio);
    final router = guardedRouter(
      guard: RouteGuard(
        sessions: sessions,
        permissions: permissions,
        paths: const GuardPaths(
          home: '/',
          signIn: '/in',
          expired: '/in',
          denied: '/in',
        ),
        screens: const {'/': 'C07'},
        public: const {'/in'},
      ),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(path: '/in', builder: (_, _) => const Text('sign in')),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('sign in'), findsOneWidget);
    await sessions.signIn(const Session(accessToken: 'a'));
    await tester.runAsync(permissions.load);
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    await sessions.signOut();
    await tester.pumpAndSettle();
    expect(find.text('sign in'), findsOneWidget);
  });
}
