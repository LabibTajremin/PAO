//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// How the merchant paid PAO.
enum PaymentMethodKind {
  /// How the merchant paid PAO.
  @JsonValue(r'cash_to_agent')
  cashToAgent(r'cash_to_agent'),

  /// How the merchant paid PAO.
  @JsonValue(r'bkash')
  bkash(r'bkash'),

  /// How the merchant paid PAO.
  @JsonValue(r'nagad')
  nagad(r'nagad'),

  /// How the merchant paid PAO.
  @JsonValue(r'bank')
  bank(r'bank');

  const PaymentMethodKind(this.value);

  final String value;

  @override
  String toString() => value;
}
