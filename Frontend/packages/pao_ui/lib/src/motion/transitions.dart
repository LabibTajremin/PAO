import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// Push and pop as a shared X axis: the new page slides in 24 dp and fades
/// in, the old one drifts 24 dp the other way and fades a little. Only
/// transform and opacity animate. The light motion set cross-fades instead.
class PaoPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder.
  const PaoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => PaoMotion.page;

  @override
  Duration get reverseTransitionDuration => PaoMotion.pop;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (context.lightMotion) {
      return FadeTransition(opacity: _curved(animation), child: child);
    }
    return SharedAxisX(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Route changes on the admin web: a quick fade, nothing moves.
class PaoFadePageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder.
  const PaoFadePageTransitionsBuilder();

  @override
  Duration get transitionDuration => PaoMotion.fast;

  @override
  Duration get reverseTransitionDuration => PaoMotion.fast;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: _curved(animation), child: child);
}

/// The shared X axis motion of [PaoPageTransitionsBuilder].
class SharedAxisX extends StatelessWidget {
  /// Animates [child] in with [animation] and out with [secondaryAnimation].
  const SharedAxisX({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  /// The page's own entrance.
  final Animation<double> animation;

  /// A page pushed on top of this one.
  final Animation<double> secondaryAnimation;

  /// The page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final width = MediaQuery.sizeOf(context).width;
    final shift = (rtl ? -PaoMotion.slide : PaoMotion.slide) / width;
    final enter = _curved(animation);
    final under = _curved(secondaryAnimation);
    return RepaintBoundary(
      child: SlideTransition(
        position: Tween(
          begin: Offset(shift, 0),
          end: Offset.zero,
        ).animate(enter),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween(
              begin: Offset.zero,
              end: Offset(-shift, 0),
            ).animate(under),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.6).animate(under),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The page transitions of every PAO app: the shared axis on Android and
/// desktop, the native swipe-back on iOS and macOS, a fade on the web.
PageTransitionsTheme paoPageTransitions({required bool web}) {
  const pao = PaoPageTransitionsBuilder();
  const cupertino = CupertinoPageTransitionsBuilder();
  const fade = PaoFadePageTransitionsBuilder();
  return PageTransitionsTheme(
    builders: {
      for (final p in TargetPlatform.values)
        p: web
            ? fade
            : p == TargetPlatform.iOS || p == TargetPlatform.macOS
            ? cupertino
            : pao,
    },
  );
}

Animation<double> _curved(Animation<double> a) => CurvedAnimation(
  parent: a,
  curve: PaoMotion.enter,
  reverseCurve: PaoMotion.exit,
);
