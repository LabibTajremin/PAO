import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/shared/form_dialog.dart';

import '../../support/harness.dart';
import 'fixtures.dart';

Future<void> _tapIn(WidgetTester tester, String text) async {
  await tester.tap(inDialog(find.text(text)).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a role is edited and applied after confirming', (tester) async {
    final h = await openSettings(tester, Routes.dashboard);
    h.http.onGet(rolesPath, (s) => s.reply(200, roleList()));
    await h.go(tester, Routes.settingsTab('roles'));
    expect(find.text('Verifier'), findsOneWidget);
    expect(find.text('2 permissions · 2 screens'), findsNWidgets(1));
    expect(find.text('1 permissions · 2 screens'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit role').first);
    await tester.pumpAndSettle();
    await _tapIn(tester, 'provider:read');
    await _tapIn(tester, 'level2:manage');
    await _tapIn(tester, 'A07');
    await _tapIn(tester, 'Save');
    expect(find.text('Apply the changes to Verifier?'), findsOneWidget);
    await _tapIn(tester, 'Cancel');
    expect(h.sent.where((o) => o.method == 'PUT'), isEmpty);
    const path = '$rolesPath/verifier';
    h.http.onPut(path, (s) => s.reply(422, apiError('ROLE_INVALID')));
    await _tapIn(tester, 'Save');
    await tester.tap(find.text('Apply now'));
    await h.settle(tester);
    expect(find.byType(FormError), findsOneWidget);
    h.http.onPut(
      path,
      (s) => s.reply(200, (roleList()['items']! as List<Object?>).first),
    );
    await _tapIn(tester, 'Save');
    await tester.tap(find.text('Apply now'));
    await h.settle(tester);
    expect(find.text('Role updated.'), findsOneWidget);
    expect(h.bodyOf(path), {
      'permissions': ['verification:review', 'level2:manage'],
      'screens': ['A02', 'A05', 'A07'],
    });
  });

  testWidgets('no roles, and a failed load', (tester) async {
    final h = await openSettings(tester, Routes.dashboard);
    h.http.onGet(
      rolesPath,
      (s) => s.reply(200, {
        'items': <Object>[],
        'allPermissions': <Object>[],
        'allScreens': <Object>[],
      }),
    );
    await h.go(tester, Routes.settingsTab('roles'));
    expect(find.text('No roles found'), findsOneWidget);
    h.http.onGet(rolesPath, (s) => s.reply(500, apiError('INTERNAL')));
    await h.go(tester, Routes.dashboard);
    await h.go(tester, Routes.settingsTab('roles'));
    expect(find.text('Try again'), findsOneWidget);
  });
}
