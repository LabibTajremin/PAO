//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ComplaintReason {
  @JsonValue(r'no_show')
  noShow(r'no_show'),
  @JsonValue(r'late')
  late_(r'late'),
  @JsonValue(r'poor_quality')
  poorQuality(r'poor_quality'),
  @JsonValue(r'overcharge')
  overcharge(r'overcharge'),
  @JsonValue(r'damage')
  damage(r'damage'),
  @JsonValue(r'behaviour')
  behaviour(r'behaviour'),
  @JsonValue(r'safety')
  safety(r'safety'),
  @JsonValue(r'customer_unavailable')
  customerUnavailable(r'customer_unavailable'),
  @JsonValue(r'payment')
  payment(r'payment'),
  @JsonValue(r'other')
  other(r'other');

  const ComplaintReason(this.value);

  final String value;

  @override
  String toString() => value;
}
