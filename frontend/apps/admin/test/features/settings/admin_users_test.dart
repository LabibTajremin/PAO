import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';

import '../../support/harness.dart';
import '../catalog/fixtures.dart' show field;
import 'fixtures.dart';

Map<String, Object?> _list() => {
  'items': [
    adminUser(),
    adminUser(
      id: karimId,
      name: 'Karim Hasan',
      roles: ['support_agent', 'catalog_manager'],
      active: false,
      totp: false,
      signedIn: false,
    ),
  ],
};

Future<Harness> _open(WidgetTester tester) async {
  final h = await openSettings(tester, Routes.dashboard);
  h.http.onGet(adminsPath, (s) => s.reply(200, _list()));
  await h.go(tester, Routes.settingsTab('admins'));
  return h;
}

Future<void> _tapIn(WidgetTester tester, String text, [Harness? h]) async {
  await tester.tap(inDialog(find.text(text)).last);
  if (h == null) {
    await tester.pumpAndSettle();
  } else {
    await h.settle(tester);
  }
}

void main() {
  testWidgets('admins show their roles, status and 2FA', (tester) async {
    await _open(tester);
    expect(find.text('rina@pao.bd'), findsOneWidget);
    expect(find.text('Last signed in 8 Oct 2026, 10:00 AM'), findsOneWidget);
    expect(find.text('Has not signed in yet'), findsOneWidget);
    expect(find.text('Deactivated'), findsOneWidget);
    expect(find.text('2FA pending'), findsOneWidget);
    expect(find.text('2FA set up'), findsOneWidget);
    expect(find.text('Support agent'), findsOneWidget);
  });

  testWidgets('an invite is checked, refused, then shows the password once', (
    tester,
  ) async {
    final h = await _open(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    await tester.tap(find.text('Invite admin'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Full name'), 'A');
    await _tapIn(tester, 'Send invite');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Write at least 2 characters.'), findsOneWidget);
    expect(find.text('Pick at least one role.'), findsOneWidget);
    await tester.enterText(field('Work email'), ' nadia@pao.bd ');
    await tester.enterText(field('Full name'), '');
    await _tapIn(tester, 'Send invite');
    expect(find.text('Fill this in.'), findsOneWidget);
    await tester.enterText(field('Full name'), 'Nadia Islam');
    await _tapIn(tester, 'Verifier');
    await _tapIn(tester, 'Super admin');
    await _tapIn(tester, 'Super admin');
    h.http.onPost(adminsPath, (s) => s.reply(409, apiError('CONFLICT')));
    await _tapIn(tester, 'Send invite', h);
    expect(
      find.text('This was already changed. Refresh and try again.'),
      findsOne,
    );
    h.http.onPost(
      adminsPath,
      (s) => s.reply(201, {
        'user': adminUser(name: 'Nadia Islam'),
        'temporaryPassword': 'temporary-password',
      }),
    );
    await _tapIn(tester, 'Send invite', h);
    expect(lastBody(h, 'POST'), {
      'email': 'nadia@pao.bd',
      'name': 'Nadia Islam',
      'roles': ['verifier'],
    });
    expect(find.text('temporary-password'), findsOneWidget);
    expect(find.textContaining('to Nadia Islam privately'), findsOneWidget);
    await tester.tap(find.byTooltip('Copy password'));
    await tester.pumpAndSettle();
    expect(copied, 'temporary-password');
    expect(find.text('Copied.'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('temporary-password'), findsNothing);
  });

  testWidgets('an invite can be cancelled', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('Invite admin'));
    await tester.pumpAndSettle();
    await _tapIn(tester, 'Cancel');
    expect(h.sent.where((o) => o.method == 'POST'), isEmpty);
  });

  testWidgets('roles change; deactivating asks first', (tester) async {
    final h = await _open(tester);
    const path = '$adminsPath/$rinaId';
    await tester.tap(find.byTooltip('Change roles or access').first);
    await tester.pumpAndSettle();
    await _tapIn(tester, 'Verifier');
    await _tapIn(tester, 'Save');
    expect(find.text('Pick at least one role.'), findsOneWidget);
    await _tapIn(tester, 'Support agent');
    await _tapIn(tester, 'Can sign in');
    await _tapIn(tester, 'Save');
    expect(find.text('Deactivate Rina Akter?'), findsOneWidget);
    await _tapIn(tester, 'Cancel');
    expect(h.sent.where((o) => o.method == 'PATCH'), isEmpty);
    h.http.onPatch(path, (s) => s.reply(409, apiError('CONFLICT')));
    await _tapIn(tester, 'Save');
    await _tapIn(tester, 'Deactivate', h);
    expect(
      find.text('This was already changed. Refresh and try again.'),
      findsOne,
    );
    h.http.onPatch(path, (s) => s.reply(200, adminUser(active: false)));
    await _tapIn(tester, 'Save');
    await _tapIn(tester, 'Deactivate', h);
    expect(find.text('Saved.'), findsOneWidget);
    expect(h.bodyOf(path), {
      'roles': ['support_agent'],
      'active': false,
    });
  });

  testWidgets('a deactivated admin is reactivated without asking', (
    tester,
  ) async {
    final h = await _open(tester);
    const path = '$adminsPath/$karimId';
    h.http.onPatch(path, (s) => s.reply(200, adminUser(id: karimId)));
    await tester.tap(find.byTooltip('Change roles or access').last);
    await tester.pumpAndSettle();
    await _tapIn(tester, 'Can sign in');
    await _tapIn(tester, 'Save', h);
    expect(h.bodyOf(path), {
      'roles': ['support_agent', 'catalog_manager'],
      'active': true,
    });
  });

  testWidgets('no admins, and a failed load', (tester) async {
    final h = await openSettings(tester, Routes.dashboard);
    h.http.onGet(adminsPath, (s) => s.reply(200, {'items': <Object>[]}));
    await h.go(tester, Routes.settingsTab('admins'));
    expect(find.text('No admin users yet'), findsOneWidget);
    h.http.onGet(adminsPath, (s) => s.reply(500, apiError('INTERNAL')));
    await h.go(tester, Routes.dashboard);
    await h.go(tester, Routes.settingsTab('admins'));
    expect(find.text('Try again'), findsOneWidget);
  });
}
