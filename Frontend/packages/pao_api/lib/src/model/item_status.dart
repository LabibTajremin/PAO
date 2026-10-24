//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ItemStatus {
  @JsonValue(r'missing')
  missing(r'missing'),
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'rejected')
  rejected(r'rejected'),
  @JsonValue(r'expired')
  expired(r'expired');

  const ItemStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
