import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/app/routes.dart';
import 'package:pao_partner/features/verification/presentation/verification_page.dart';

import '../../support/harness.dart';

void main() {
  Future<Harness> start(WidgetTester tester) async {
    final h = await Harness.create();
    h.http
      ..onGet(
        '/v1/me/permissions',
        (s) => s.reply(200, {
          'roles': ['provider'],
          'permissions': <String>[],
          'screens': allScreens,
        }),
      )
      ..onGet(
        '/v1/provider/verification',
        (s) => s.reply(200, verification(cleared: false, level: 0)),
      );
    await h.pumpApp(tester, Routes.phone);
    return h;
  }

  testWidgets('phone entry validates, then sends a code and opens M04', (
    tester,
  ) async {
    final h = await start(tester);
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Send code'));
    await h.settle(tester);
    expect(
      find.text('Enter an 11-digit Bangladeshi mobile number.'),
      findsOneWidget,
    );
    h.http.onPost(
      '/v1/auth/otp/request',
      (s) => s.reply(503, {
        'error': {'code': 'INTERNAL', 'message': 'x'},
      }),
    );
    await tester.enterText(find.byType(TextField), '1712345678');
    await tester.tap(find.text('Send code'));
    await h.settle(tester);
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http.onPost(
      '/v1/auth/otp/request',
      (s) => s.reply(202, {'expiresInSeconds': 300, 'resendAfterSeconds': 30}),
    );
    await tester.tap(find.text('Send code'));
    await h.settle(tester);
    expect(find.text('We sent it to 01712345678.'), findsOneWidget);
    expect(h.bodyOf('/v1/auth/otp/request'), {
      'phone': '01712345678',
      'purpose': 'login',
    });
  });

  testWidgets('a wrong code shows the error; the right one signs in', (
    tester,
  ) async {
    final h = await start(tester);
    await h.go(tester, '${Routes.otp}?phone=01712345678');
    h.http.onPost(
      '/v1/auth/otp/verify',
      (s) => s.reply(422, {
        'error': {'code': 'OTP_INVALID', 'message': 'x'},
      }),
    );
    await tester.enterText(find.byType(TextField), '000000');
    await h.settle(tester);
    expect(find.text('That code is not right.'), findsOneWidget);
    h.http.onPost(
      '/v1/auth/otp/verify',
      (s) => s.reply(200, {
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'expiresInSeconds': 900,
        'account': {
          'id': '11111111-1111-1111-1111-111111111111',
          'roles': ['provider'],
          'status': 'active',
          'createdAt': '2026-10-09T00:00:00Z',
        },
      }),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await h.settle(tester);
    expect(h.services.sessions.session!.refreshToken, 'refresh');
    expect(h.bodyOf('/v1/auth/otp/verify'), {
      'phone': '01712345678',
      'code': '123456',
      'app': 'partner',
    });
    expect(find.byType(VerificationPage), findsOneWidget);
  });

  testWidgets('resend becomes available after the countdown', (tester) async {
    final h = await start(tester);
    await h.go(tester, '${Routes.otp}?phone=01712345678');
    expect(find.text('Resend code in 30s'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    h.http.onPost(
      '/v1/auth/otp/request',
      (s) => s.reply(202, {'expiresInSeconds': 300, 'resendAfterSeconds': 60}),
    );
    await tester.tap(find.text('Resend code'));
    await h.settle(tester);
    expect(
      find.textContaining(RegExp(r'Resend code in 5\d|60')),
      findsOneWidget,
    );
  });
}
