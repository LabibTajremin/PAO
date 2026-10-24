//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ComplaintStatus {
  @JsonValue(r'open')
  open(r'open'),
  @JsonValue(r'assigned')
  assigned(r'assigned'),
  @JsonValue(r'resolved')
  resolved(r'resolved');

  const ComplaintStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
