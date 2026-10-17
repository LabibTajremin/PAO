import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/account/domain/account_repository.dart';
import 'package:pao_customer/features/account/presentation/account_deleted_page.dart';
import 'package:pao_customer/features/account/presentation/account_page.dart';
import 'package:pao_customer/features/account/presentation/delete_account_cubit.dart';
import 'package:pao_customer/features/auth/presentation/phone_page.dart';

import '../../support/harness.dart';

class _Repo implements DeleteAccountRepository {
  final gate = Completer<void>();
  int requests = 0;
  int deletes = 0;

  @override
  Future<String> requestCode() async {
    requests++;
    await gate.future;
    return '+8801712345678';
  }

  @override
  Future<void> delete(String code) async {
    deletes++;
    await gate.future;
  }
}

void main() {
  test('the cubit ignores repeats while busy and short codes', () async {
    final repo = _Repo();
    final cubit = DeleteAccountCubit(repo);
    await cubit.confirm();
    final first = cubit.requestCode();
    await cubit.requestCode();
    repo.gate.complete();
    await first;
    cubit.typed('123456');
    final deleting = cubit.confirm();
    await cubit.confirm();
    await deleting;
    expect([repo.requests, repo.deletes, cubit.state.deleted], [1, 1, true]);
    await cubit.close();
  });

  testWidgets('deleting confirms with a code, then says goodbye signed out', (
    tester,
  ) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester);
    await h.pumpApp(tester, Routes.account);
    await tester.tap(find.text('Delete account'));
    await h.settle(tester);
    expect(find.text('Before you go'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await h.settle(tester);
    expect(find.byType(AccountPage), findsOneWidget);
    await tester.tap(find.text('Delete account'));
    await h.settle(tester);
    h.http.onGet('/v1/me', (s) => s.reply(503, apiError('INTERNAL')));
    await tester.tap(find.text('Send confirmation code'));
    await h.settle(tester);
    expect(
      find.text('Our service had a problem. Please try again.'),
      findsOneWidget,
    );
    h.http
      ..onGet(
        '/v1/me',
        (s) => s.reply(200, {
          'id': 'a1',
          'phone': '+8801712345678',
          'roles': ['customer'],
          'status': 'active',
          'createdAt': '2026-01-01T00:00:00Z',
        }),
      )
      ..onPost(
        '/v1/auth/otp/request',
        (s) =>
            s.reply(202, {'expiresInSeconds': 300, 'resendAfterSeconds': 60}),
      );
    await tester.tap(find.text('Send confirmation code'));
    await h.settle(tester);
    expect(find.textContaining('+8801712345678'), findsOneWidget);
    expect(h.bodyOf('/v1/auth/otp/request'), {
      'phone': '+8801712345678',
      'purpose': 'delete_account',
    });
    await _confirm(tester, h);
  });
}

Future<void> _confirm(WidgetTester tester, Harness h) async {
  await tester.tap(find.text('Delete my account'));
  await h.settle(tester);
  expect(h.sent.where((o) => o.method == 'DELETE'), isEmpty);
  h.http.onDelete('/v1/me', (s) => s.reply(422, apiError('OTP_INVALID')));
  await tester.enterText(find.byType(TextField), '111111');
  await h.settle(tester);
  await tester.tap(find.text('Delete my account'));
  await h.settle(tester);
  expect(find.byType(PhonePage), findsNothing);
  expect(find.text('That code is not right.'), findsOneWidget);
  await tester.tap(find.text('Send a new code'));
  await h.settle(tester);
  expect(h.sent.where((o) => o.path == '/v1/auth/otp/request'), hasLength(2));
  h.http.onDelete('/v1/me', (s) => s.reply(204, null));
  await tester.enterText(find.byType(TextField), '123456');
  await h.settle(tester);
  await tester.tap(find.text('Delete my account'));
  await h.settle(tester);
  expect(h.bodyOf('/v1/me'), {'code': '123456'});
  expect(find.byType(AccountDeletedPage), findsOneWidget);
  expect(h.services.sessions.signedIn, isFalse);
  expect(h.sent.any((o) => o.path == '/v1/auth/logout'), isFalse);
  await tester.tap(find.text('Continue'));
  await h.settle(tester);
  expect(find.byType(PhonePage), findsOneWidget);
}
