//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// Customer-facing badge for the level (PRD §6.1).
enum Badge {
  /// Customer-facing badge for the level (PRD §6.1).
  @JsonValue(r'none')
  none(r'none'),

  /// Customer-facing badge for the level (PRD §6.1).
  @JsonValue(r'verified')
  verified(r'verified'),

  /// Customer-facing badge for the level (PRD §6.1).
  @JsonValue(r'verified_pro')
  verifiedPro(r'verified_pro');

  const Badge(this.value);

  final String value;

  @override
  String toString() => value;
}
