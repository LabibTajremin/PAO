import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

import 'golden_test.dart' show loadFonts;

const _copy = {
  'en': (
    'Welcome to PAO',
    'We will text you a code to sign in.',
    'Ask for it. PAO it.',
  ),
  'bn': (
    'পাও-তে স্বাগতম',
    'সাইন ইনের জন্য আমরা একটি কোড পাঠাব।',
    'যা চাও, তাই PAO',
  ),
};

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required bool dark,
  required String lang,
}) async {
  // A 393 pt iPhone screen, the smaller of the two the phase names.
  tester.view
    ..physicalSize = const Size(393, 852)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? PaoTheme.dark() : PaoTheme.light(),
      locale: Locale(lang),
      supportedLocales: PaoLocales.all,
      localizationsDelegates: const [
        PaoL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: page,
    ),
  );
  // The SVG pictures decode off the frame; let them land before the capture.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  for (final dark in [false, true]) {
    for (final lang in ['en', 'bn']) {
      final name = '${dark ? 'dark' : 'light'}_$lang';
      final (title, subtitle, tagline) = _copy[lang]!;
      testWidgets('sign-in, $name', (tester) async {
        await _pump(
          tester,
          PaoSignInLayout(
            hero: const PaoArtwork('customer.signin.hero'),
            tagline: tagline,
            title: title,
            subtitle: subtitle,
            children: [
              PaoTextField(
                label: 'Mobile number',
                prefix: '+880',
                hint: '1XXXXXXXXX',
                controller: TextEditingController(),
              ),
              const SizedBox(height: PaoSpace.xl),
              PaoButton(label: 'Send OTP', onPressed: () {}),
            ],
          ),
          dark: dark,
          lang: lang,
        );
        expect(find.text(title), findsOne);
        await expectLater(
          find.byType(PaoSignInLayout),
          matchesGoldenFile('goldens/signin_$name.png'),
        );
      });
      testWidgets('welcome slide, $name', (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: PaoOnboardingSlide(
              illustration: const PaoArtwork('customer.onboarding.1'),
              title: title,
              body: subtitle,
            ),
          ),
          dark: dark,
          lang: lang,
        );
        await expectLater(
          find.byType(PaoOnboardingSlide),
          matchesGoldenFile('goldens/welcome_$name.png'),
        );
      });
    }
  }
}
