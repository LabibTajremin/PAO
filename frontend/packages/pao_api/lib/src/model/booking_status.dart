//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum BookingStatus {
  @JsonValue(r'requested')
  requested(r'requested'),
  @JsonValue(r'accepted')
  accepted(r'accepted'),
  @JsonValue(r'on_the_way')
  onTheWay(r'on_the_way'),
  @JsonValue(r'arrived')
  arrived(r'arrived'),
  @JsonValue(r'in_progress')
  inProgress(r'in_progress'),
  @JsonValue(r'completed')
  completed(r'completed'),
  @JsonValue(r'rejected')
  rejected(r'rejected'),
  @JsonValue(r'timed_out')
  timedOut(r'timed_out'),
  @JsonValue(r'cancelled')
  cancelled(r'cancelled');

  const BookingStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
