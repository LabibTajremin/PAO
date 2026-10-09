import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:pao_admin/app/app.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';

void main() {
  late AppServices services;

  Future<void> boot(
    WidgetTester tester, {
    List<String> screens = const [],
  }) async {
    final dio = Dio();
    DioAdapter(dio: dio).onGet(
      '/v1/me/permissions',
      (s) => s.reply(200, {
        'roles': <String>[],
        'permissions': <String>[],
        'screens': screens,
      }),
    );
    services = AppServices(
      sessions: SessionManager(MemorySessionStore()),
      permissions: PermissionService(dio),
      locale: LocaleController(PaoLocales.english),
    );
    await tester.pumpWidget(PaoApp(services: services));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await services.sessions.signIn(const Session(accessToken: 'a'));
    await tester.runAsync(services.permissions.load);
    await tester.pumpAndSettle();
  }

  testWidgets('signed-out users land on sign-in and can switch language', (
    tester,
  ) async {
    await boot(tester);
    expect(find.text('PAO Admin'), findsWidgets);
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(services.locale.isBangla, isTrue);
    expect(find.text('এগিয়ে যান'), findsOneWidget);
  });

  testWidgets('a permitted account reaches home and can sign out', (
    tester,
  ) async {
    await boot(tester, screens: ['A02']);
    await signIn(tester);
    expect(find.text('Log out'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('a role without the home screen is refused', (tester) async {
    await boot(tester);
    await signIn(tester);
    expect(find.text('You do not have access to this screen.'), findsOneWidget);
  });

  testWidgets('an expired session shows welcome back', (tester) async {
    await boot(tester, screens: ['A02']);
    await signIn(tester);
    await services.sessions.signOut(expired: true);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsNothing);
  });
}
