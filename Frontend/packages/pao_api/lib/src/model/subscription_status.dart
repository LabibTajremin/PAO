//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum SubscriptionStatus {
  @JsonValue(r'requested')
  requested(r'requested'),
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'paused')
  paused(r'paused'),
  @JsonValue(r'finished')
  finished(r'finished'),
  @JsonValue(r'declined')
  declined(r'declined'),
  @JsonValue(r'cancelled')
  cancelled(r'cancelled');

  const SubscriptionStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
