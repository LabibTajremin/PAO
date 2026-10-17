import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Pumps [child] in a themed, localised app.
Future<void> pumpPao(
  WidgetTester tester,
  Widget child, {
  AccentPreset accent = AccentPreset.midnight,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) => tester.pumpWidget(
  MaterialApp(
    theme: PaoTheme.light(accent: accent),
    locale: locale,
    supportedLocales: PaoLocales.all,
    localizationsDelegates: const [
      PaoL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: Scaffold(body: child),
  ),
);

/// Gives the test a tall phone-width screen so long pages build fully.
void tallScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
