import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// The leaf corner, PAO's signature shape: three soft corners and one tight
/// "tip" at the bottom right (ADR 0033). Keep the tip on the same corner
/// everywhere so the shape reads as one brand mark.
abstract final class PaoShape {
  /// The soft corners.
  static const double round = 22;

  /// The tip.
  static const double tip = 4;

  /// Cards, primary buttons and selected chips.
  static const BorderRadius leaf = BorderRadius.only(
    topLeft: Radius.circular(round),
    topRight: Radius.circular(round),
    bottomLeft: Radius.circular(round),
    bottomRight: Radius.circular(tip),
  );

  /// Small elements such as icon tiles, where 20 would turn them into circles.
  static const BorderRadius leafSmall = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(14),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(3),
  );

  /// Bottom sheets: only the top edge is visible, so the tip moves to the
  /// top right there.
  static const BorderRadius sheet = BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(tip),
  );
}

/// Motion stays subtle: short, eased transitions only.
abstract final class PaoMotion {
  /// State changes on small controls such as chips.
  static const fast = Duration(milliseconds: 150);

  /// Larger surfaces such as segments and boxes.
  static const base = Duration(milliseconds: 200);

  /// The easing for every PAO transition.
  static const Curve curve = Curves.easeOutCubic;
}
