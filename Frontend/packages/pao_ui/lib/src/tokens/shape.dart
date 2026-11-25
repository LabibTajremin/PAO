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
