import 'dart:async';

import 'package:dio/browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/app/services.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_e2e/pao_e2e.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The admin panel's services against the e2e stack, wired as `main.dart`
/// wires them in the browser.
AppServices webServices() {
  final sessions = SessionManager(MemorySessionStore());
  late final PermissionService permissions;
  final api = createApiClient(
    const Env(
      apiBaseUrl: String.fromEnvironment('PAO_API_BASE_URL'),
      flavour: 'e2e',
    ),
    sessions,
    adapter: BrowserHttpClientAdapter(withCredentials: true),
    onRefreshed: () => unawaited(permissions.load()),
  );
  permissions = PermissionService(api);
  return AppServices(
    sessions: sessions,
    permissions: permissions,
    locale: LocaleController(PaoLocales.english),
    api: api,
  );
}

/// Signs [email] in with the seeded password and an authenticator code (A01).
/// On a first sign-in the panel shows the key to enrol; otherwise the key
/// comes from [knownSecret]. A code is accepted once, so a code another
/// journey just used is retried in the next 30-second window.
Future<void> signInWithTotp(
  WidgetTester tester, {
  required String email,
  required String password,
  required String knownSecret,
}) async {
  await typeInto(tester, 'Work email', email);
  await typeInto(tester, 'Password', password);
  await tapText(tester, 'Sign in');
  await pumpUntil(tester, find.byType(PaoOtpInput));
  final shown = find.byType(SelectableText).evaluate();
  final secret = shown.isEmpty
      ? knownSecret
      : (shown.single.widget as SelectableText).data!;
  for (var attempt = 0; attempt < 3; attempt++) {
    await enterCode(tester, totp(secret, DateTime.now()));
    await idle(tester, const Duration(seconds: 2));
    if (find.byType(PaoOtpInput).evaluate().isEmpty) return;
    final wait = nextTotpWindow(DateTime.now()).difference(DateTime.now());
    await idle(tester, wait + const Duration(seconds: 1));
  }
  fail('the authenticator code was refused three times');
}
