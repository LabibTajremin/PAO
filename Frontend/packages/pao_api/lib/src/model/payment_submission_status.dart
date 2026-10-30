//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum PaymentSubmissionStatus {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'rejected')
  rejected(r'rejected');

  const PaymentSubmissionStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
