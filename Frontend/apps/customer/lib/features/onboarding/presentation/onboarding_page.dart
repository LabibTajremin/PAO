import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/app/services.dart';
import 'package:pao_customer/features/onboarding/data/onboarding_prefs.dart';
import 'package:pao_customer/features/onboarding/presentation/onboarding_slide.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// Onboarding (C02, C31, C32): what PAO offers and the language choice (C-15).
class OnboardingPage extends StatefulWidget {
  /// Creates the page.
  const OnboardingPage({required this.services, super.key});

  /// App services.
  final AppServices services;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final s = widget.services;
    await completeOnboarding(s.prefs, s.locale.value.languageCode);
    if (mounted) context.go(Routes.phone);
  }

  Future<void> _next(int count) => _index == count - 1
      ? _finish()
      : _pages.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final slides = [
      (Icons.near_me_outlined, t.onbSlide1Title, t.onbSlide1Body),
      (Icons.verified_user_outlined, t.onbSlide2Title, t.onbSlide2Body),
      (Icons.sell_outlined, t.onbSlide3Title, t.onbSlide3Body),
    ];
    final last = _index == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(services: widget.services, onSkip: _finish),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (icon, title, body) in slides)
                    OnboardingSlide(icon: icon, title: title, body: body),
                ],
              ),
            ),
            _Dots(count: slides.length, index: _index),
            Padding(
              padding: const EdgeInsets.all(PaoSpace.xl),
              child: PaoButton(
                label: last ? t.onbStart : t.onbNext,
                onPressed: () => _next(slides.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.services, required this.onSkip});

  final AppServices services;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PaoSpace.xl,
      PaoSpace.md,
      PaoSpace.sm,
      0,
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            label: context.t.onbLanguage,
            child: PaoLanguageSwitch(controller: services.locale),
          ),
        ),
        TextButton(onPressed: onSkip, child: Text(context.t.onbSkip)),
      ],
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        Container(
          width: i == index ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: PaoSpace.xs),
          decoration: BoxDecoration(
            color: i == index ? context.pao.accent.primary : PaoColors.border,
            borderRadius: BorderRadius.circular(PaoRadius.pill),
          ),
        ),
    ],
  );
}
