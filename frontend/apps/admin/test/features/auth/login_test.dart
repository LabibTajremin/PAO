import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/routes.dart';
import 'package:pao_admin/features/auth/data/session_restore.dart';
import 'package:pao_admin/features/auth/presentation/login_page.dart';
import 'package:pao_admin/features/auth/presentation/password_page.dart';

import '../../support/harness.dart';

const _challenge = '0192f4a6-1c2b-7c1d-9e3f-5a6b7c8d9e0f';

Map<String, Object?> _tokens() => {
  'accessToken': 'access',
  'expiresInSeconds': 900,
  'account': {
    'id': '11111111-1111-1111-1111-111111111111',
    'roles': ['verifier'],
    'status': 'active',
    'createdAt': '2026-10-09T00:00:00Z',
  },
};

Future<Harness> _start(WidgetTester tester) async {
  desktop(tester);
  final h = Harness.create()..permits(allScreens);
  await h.pumpApp(tester, Routes.login);
  return h;
}

Future<void> _password(WidgetTester tester, Harness h) async {
  await tester.enterText(find.byType(TextField).at(0), ' rina@pao.bd ');
  await tester.enterText(find.byType(TextField).at(1), 'temporary-pass');
  await tester.tap(find.text('Sign in'));
  await h.settle(tester);
}

void main() {
  testWidgets('a wrong password, then enrolment, a wrong code and sign-in', (
    tester,
  ) async {
    final h = await _start(tester);
    h.http.onPost(
      '/v1/auth/admin/login',
      (s) => s.reply(401, apiError('INVALID_CREDENTIALS')),
    );
    await _password(tester, h);
    expect(find.text('Email or password is wrong.'), findsOneWidget);
    h.http.onPost(
      '/v1/auth/admin/login',
      (s) => s.reply(200, {
        'challengeId': _challenge,
        'expiresInSeconds': 300,
        'totpEnrolment': {
          'secret': 'JBSWY3DPEHPK3PXP',
          'otpauthUrl': 'otpauth://x',
        },
      }),
    );
    await _password(tester, h);
    expect(h.bodyOf('/v1/auth/admin/login'), {
      'email': 'rina@pao.bd',
      'password': 'temporary-pass',
    });
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    h.http.onPost(
      '/v1/auth/admin/totp',
      (s) => s.reply(422, apiError('TOTP_INVALID')),
    );
    await tester.enterText(find.byType(TextField), '000000');
    await h.settle(tester);
    expect(find.text('That authenticator code is not right.'), findsOneWidget);
    h.http.onPost('/v1/auth/admin/totp', (s) => s.reply(200, _tokens()));
    await tester.enterText(find.byType(TextField), '123456');
    await h.settle(tester);
    expect(h.bodyOf('/v1/auth/admin/totp'), {
      'challengeId': _challenge,
      'code': '123456',
    });
    expect(find.text('A02'), findsOneWidget);
  });

  testWidgets('another account goes back to the password step', (tester) async {
    final h = await _start(tester);
    h.http.onPost(
      '/v1/auth/admin/login',
      (s) => s.reply(200, {'challengeId': _challenge, 'expiresInSeconds': 300}),
    );
    await _password(tester, h);
    await tester.tap(find.text('Use another account'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('a temporary password must be replaced first', (tester) async {
    final h = await _start(tester);
    h.http
      ..onPost(
        '/v1/auth/admin/login',
        (s) => s.reply(200, {
          'challengeId': _challenge,
          'expiresInSeconds': 300,
          'mustChangePassword': true,
        }),
      )
      ..onPost('/v1/auth/admin/totp', (s) => s.reply(200, _tokens()));
    await _password(tester, h);
    await tester.enterText(find.byType(TextField), '123456');
    await h.settle(tester);
    expect(find.byType(PasswordPage), findsOneWidget);
    await h.go(tester, Routes.catalog);
    expect(find.byType(PasswordPage), findsOneWidget);
    await _change(tester, h);
  });

  testWidgets('a reload restores the session from the refresh cookie', (
    tester,
  ) async {
    desktop(tester);
    final h = Harness.create()..permits(allScreens);
    h.http.onPost('/v1/auth/refresh', (s) => s.reply(401, null));
    await tester.runAsync(() => restoreSession(h.services));
    expect(h.services.sessions.signedIn, isFalse);
    h.http.onPost('/v1/auth/refresh', (s) => s.reply(200, _tokens()));
    await tester.runAsync(() => restoreSession(h.services));
    expect(h.services.sessions.session!.accessToken, 'access');
    await h.pumpApp(tester, Routes.login);
    expect(find.byType(LoginPage), findsNothing);
  });
}

Future<void> _change(WidgetTester tester, Harness h) async {
  Future<void> submit(String current, String next, String repeat) async {
    for (final (i, text) in [current, next, repeat].indexed) {
      await tester.enterText(find.byType(TextField).at(i), text);
    }
    await tester.tap(find.text('Save'));
    await h.settle(tester);
  }

  await submit('temporary-pass', 'short', 'short');
  expect(find.text('The new password needs at least 12 characters.'), findsOne);
  await submit('temporary-pass', 'a-long-passphrase', 'a-long-passphrase!');
  expect(find.text('The two new passwords are not the same.'), findsOne);
  h.http.onPost(
    '/v1/auth/admin/password',
    (s) => s.reply(401, apiError('INVALID_CREDENTIALS')),
  );
  await submit('wrong-pass', 'a-long-passphrase', 'a-long-passphrase');
  expect(find.text('Email or password is wrong.'), findsOneWidget);
  h.http.onPost('/v1/auth/admin/password', (s) => s.reply(204, null));
  await submit('temporary-pass', 'a-long-passphrase', 'a-long-passphrase');
  expect(h.bodyOf('/v1/auth/admin/password'), {
    'currentPassword': 'temporary-pass',
    'newPassword': 'a-long-passphrase',
  });
  expect(find.text('A02'), findsOneWidget);
}
