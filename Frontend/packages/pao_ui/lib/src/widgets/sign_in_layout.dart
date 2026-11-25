import 'package:flutter/material.dart';
import 'package:pao_ui/src/motion/hero.dart';
import 'package:pao_ui/src/tokens/accent.dart';
import 'package:pao_ui/src/tokens/colors.dart';
import 'package:pao_ui/src/tokens/metrics.dart';
import 'package:pao_ui/src/tokens/shape.dart';
import 'package:pao_ui/src/widgets/logo.dart';

/// The sign-in page of the owner's demo (P24): the hero illustration fills the
/// top ~55% with the inverse wordmark and [tagline] over it, and a rounded
/// sheet holding [title], [subtitle] and the form [children] rises over
/// its lower edge. The page scrolls, so the form stays reachable above the
/// keyboard.
class PaoSignInLayout extends StatelessWidget {
  /// Creates the layout.
  const PaoSignInLayout({
    required this.hero,
    required this.tagline,
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  /// The illustration, usually the app's `*.signin.hero` slot.
  final Widget hero;

  /// The admin-set tagline in the current language.
  final String tagline;

  /// The sheet's heading.
  final String title;

  /// One line under the heading.
  final String subtitle;

  /// The form.
  final List<Widget> children;

  /// The hero's share of the screen height.
  static const heroShare = .55;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // The seed heroes are drawn on this navy, so the band behind them matches
    // in both themes.
    final navy = AccentPreset.navy.primary;
    return Scaffold(
      backgroundColor: navy,
      body: LayoutBuilder(
        builder: (context, box) {
          final heroHeight = box.maxHeight * heroShare;
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: heroHeight,
                  width: box.maxWidth,
                  child: _Hero(
                    hero: PaoHero(tag: PaoHero.signInArt, child: hero),
                    tagline: tagline,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: box.maxHeight - heroHeight + PaoSpace.xxl,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -PaoSpace.xxl),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.pao.paper,
                        borderRadius: PaoShape.sheet,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(PaoSpace.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(title, style: text.headlineSmall),
                            const SizedBox(height: PaoSpace.xs),
                            Text(
                              subtitle,
                              style: text.bodyMedium!.copyWith(
                                color: context.pao.inkMuted,
                              ),
                            ),
                            const SizedBox(height: PaoSpace.xl),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.hero, required this.tagline});

  final Widget hero;
  final String tagline;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: 1170, child: hero),
      ),
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(PaoSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PaoLogo(
                variant: PaoLogoVariant.wordmark,
                height: 32,
                inverse: true,
              ),
              const SizedBox(height: PaoSpace.sm),
              Text(
                tagline,
                style: Theme.of(context).textTheme.titleMedium!
                    .copyWith(color: PaoColors.canvas),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
