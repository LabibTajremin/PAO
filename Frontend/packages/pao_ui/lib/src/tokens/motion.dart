import 'package:flutter/widgets.dart';

/// The only durations and curves PAO animates with (P27,
/// `docs/guides/motion.md`): short, eased out on enter and a little quicker on
/// exit, never blocking input.
abstract final class PaoMotion {
  /// A finger on a button or card.
  static const press = Duration(milliseconds: 100);

  /// Small state changes: chips, skeleton to content.
  static const fast = Duration(milliseconds: 150);

  /// Larger surfaces: segments, tab switches, panels.
  static const base = Duration(milliseconds: 220);

  /// A page pushed on top.
  static const page = Duration(milliseconds: 280);

  /// A page popped off.
  static const pop = Duration(milliseconds: 220);

  /// A bottom sheet rising.
  static const sheet = Duration(milliseconds: 300);

  /// The few moments that deserve attention: a check mark, a stepper line.
  static const emphasis = Duration(milliseconds: 400);

  /// Between the logo letters on opening.
  static const letterStagger = Duration(milliseconds: 60);

  /// Between the first list items on first load.
  static const itemStagger = Duration(milliseconds: 30);

  /// Entering.
  static const Curve enter = Curves.easeOutCubic;

  /// Leaving.
  static const Curve exit = Curves.easeInCubic;

  /// Emphasised moves.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// The logo letters only: a 4% overshoot at most.
  static const Curve gentleBack = Cubic(0.34, 1.3, 0.64, 1);

  /// How far a pushed page slides, in logical pixels.
  static const slide = 24.0;

  /// How far the first screen rises after the logo.
  static const rise = 12.0;

  /// How far a list item rises on first load.
  static const itemRise = 8.0;

  /// How many list items stagger in; later ones simply appear.
  static const staggeredItems = 6;
}

/// Whether the whole app uses the light motion set: the OS asked for reduced
/// motion, or [lowEnd] (a low-RAM phone or battery saver, detected once at
/// start). The light set cross-fades only, at 70% of each duration, with no
/// stagger, hero or burst.
class PaoMotionScope extends InheritedWidget {
  /// Scopes [child] to the device class [lowEnd].
  const PaoMotionScope({required this.lowEnd, required super.child, super.key});

  /// A low-end device or battery saver.
  final bool lowEnd;

  @override
  bool updateShouldNotify(PaoMotionScope oldWidget) =>
      lowEnd != oldWidget.lowEnd;
}

/// Motion choices read from the tree.
extension PaoMotionContext on BuildContext {
  /// Whether to use the light motion set.
  bool get lightMotion =>
      MediaQuery.maybeDisableAnimationsOf(this) == true ||
      (dependOnInheritedWidgetOfExactType<PaoMotionScope>()?.lowEnd ?? false);

  /// [d], shortened in the light set.
  Duration motion(Duration d) => lightMotion ? d * 0.7 : d;
}
