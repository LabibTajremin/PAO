import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Corner radii (ADR-0038): calm, even corners. The names come from the
/// earlier leaf shape and stay so screens keep their meaning.
abstract final class PaoShape {
  /// Cards, primary buttons and selected chips.
  static const double round = 16;

  /// Small elements such as icon tiles and inputs.
  static const double small = 12;

  /// The top corners of bottom sheets.
  static const double sheetRound = 24;

  /// Cards, primary buttons and selected chips.
  static const BorderRadius leaf = BorderRadius.all(Radius.circular(round));

  /// Small elements such as icon tiles, where 16 would make them look round.
  static const BorderRadius leafSmall = BorderRadius.all(
    Radius.circular(small),
  );

  /// Bottom sheets: only the top edge is visible.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(sheetRound),
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
