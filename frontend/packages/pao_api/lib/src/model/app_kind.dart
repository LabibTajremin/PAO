//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// The app signing in; signing in to the partner app adds the provider role (PRD §3).
enum AppKind {
  /// The app signing in; signing in to the partner app adds the provider role (PRD §3).
  @JsonValue(r'customer')
  customer(r'customer'),

  /// The app signing in; signing in to the partner app adds the provider role (PRD §3).
  @JsonValue(r'partner')
  partner(r'partner');

  const AppKind(this.value);

  final String value;

  @override
  String toString() => value;
}
