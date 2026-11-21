import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

void main() {
  for (final (locale, title, button) in [
    ('en', 'Turn on notifications', 'Continue'),
    ('bn', 'নোটিফিকেশন চালু করুন', 'চালিয়ে যান'),
  ]) {
    testWidgets('the reason sheet explains and closes ($locale)', (
      tester,
    ) async {
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: PaoTheme.light(),
          locale: Locale(locale),
          supportedLocales: PaoLocales.all,
          localizationsDelegates: const [
            PaoL10n.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showPushReason(context);
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(find.text(title), findsNothing);
      expect(closed, isTrue);
    });
  }
}
