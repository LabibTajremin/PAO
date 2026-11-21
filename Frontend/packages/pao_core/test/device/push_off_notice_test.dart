import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

class _Push extends NoPushService {
  bool on = false;
  int settingsOpened = 0;

  @override
  Future<bool> allowed() async => on;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

void main() {
  testWidgets('shows while blocked, opens settings, hides after resume', (
    tester,
  ) async {
    final push = _Push();
    await tester.pumpWidget(
      MaterialApp(
        theme: PaoTheme.light(),
        locale: const Locale('en'),
        supportedLocales: PaoLocales.all,
        localizationsDelegates: const [
          PaoL10n.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: PushOffNotice(push: push)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text("Notifications are off, so booking updates won't pop up."),
      findsOneWidget,
    );
    await tester.tap(find.text('Turn on'));
    expect(push.settingsOpened, 1);
    push.on = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(find.text('Turn on'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Turn on'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
