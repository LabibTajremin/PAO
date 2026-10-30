//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum Gender {
  @JsonValue(r'female')
  female(r'female'),
  @JsonValue(r'male')
  male(r'male'),
  @JsonValue(r'other')
  other(r'other');

  const Gender(this.value);

  final String value;

  @override
  String toString() => value;
}
