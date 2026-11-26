import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pao_ui/src/tokens/motion.dart';

/// The native splash colours (`tools/brand/splash.sh`), so the hand-over to
/// Flutter shows no flash.
abstract final class PaoSplash {
  /// Light mode background.
  static const light = Color(0xFFF6F4EC);

  /// Dark mode background.
  static const dark = Color(0xFF0E1322);

  /// The tile's size on iOS and Android 12+, in logical pixels.
  static const tile = 120.0;
}

/// The splash tile drawn as four layers, so each letter of PAO can settle on
/// its own, 60 ms apart: it dips to 92% and settles back on
/// [PaoMotion.gentleBack]. Every letter starts and ends at full size, so the
/// first frame is the native splash exactly and nothing jumps at the hand-over.
class OpeningLogo extends StatelessWidget {
  /// Draws the logo with its letters at [progress] of their settle.
  const OpeningLogo({required this.progress, required this.dark, super.key});

  /// The settle, 0 to 1.
  final Animation<double> progress;

  /// Whether to draw the inverse (dark mode) tile.
  final bool dark;

  static const _letters = ['P', 'A', 'O'];

  static final _dip = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 0.92,
      ).chain(CurveTween(curve: PaoMotion.exit)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.92,
        end: 1,
      ).chain(CurveTween(curve: PaoMotion.gentleBack)),
      weight: 70,
    ),
  ]);

  String _asset(String layer) =>
      'assets/brand/opening/$layer-${dark ? 'dark' : 'light'}.svg';

  Widget _layer(String layer) => SvgPicture.asset(
    _asset(layer),
    package: 'pao_ui',
    width: PaoSplash.tile,
    height: PaoSplash.tile,
  );

  Animation<double> _letter(int i) {
    final total = PaoMotion.letterStagger * 2 + PaoMotion.base;
    final start = PaoMotion.letterStagger * i;
    return CurvedAnimation(
      parent: progress,
      curve: Interval(
        start.inMicroseconds / total.inMicroseconds,
        (start + PaoMotion.base).inMicroseconds / total.inMicroseconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'PAO',
    image: true,
    child: SizedBox.square(
      dimension: PaoSplash.tile,
      child: Stack(
        children: [
          _layer('tile'),
          for (final (i, l) in _letters.indexed)
            ScaleTransition(scale: _dip.animate(_letter(i)), child: _layer(l)),
        ],
      ),
    ),
  );
}

/// How long the letters take to settle.
Duration get openingSettle => PaoMotion.letterStagger * 2 + PaoMotion.base;

/// Loads the opening layers into the SVG cache, so the first Flutter frame
/// can draw the splash logo; `main` awaits it before `runApp`.
Future<void> precacheOpening() => Future.wait([
  for (final mode in ['light', 'dark'])
    for (final layer in ['tile', 'P', 'A', 'O'])
      _cache('assets/brand/opening/$layer-$mode.svg'),
]);

Future<void> _cache(String asset) {
  final loader = SvgAssetLoader(asset, packageName: 'pao_ui');
  return svg.cache.putIfAbsent(
    loader.cacheKey(null),
    () => loader.loadBytes(null),
  );
}
