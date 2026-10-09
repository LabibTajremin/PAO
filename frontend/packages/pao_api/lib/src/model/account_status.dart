//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// PRD §6.4 account lifecycle.
enum AccountStatus {
  /// PRD §6.4 account lifecycle.
  @JsonValue(r'pending')
  pending(r'pending'),

  /// PRD §6.4 account lifecycle.
  @JsonValue(r'active')
  active(r'active'),

  /// PRD §6.4 account lifecycle.
  @JsonValue(r'suspended')
  suspended(r'suspended'),

  /// PRD §6.4 account lifecycle.
  @JsonValue(r'banned')
  banned(r'banned');

  const AccountStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
