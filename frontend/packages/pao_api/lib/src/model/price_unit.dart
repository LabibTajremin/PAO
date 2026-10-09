//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// What one quantity means for a sub-service.
enum PriceUnit {
  /// What one quantity means for a sub-service.
  @JsonValue(r'job')
  job(r'job'),

  /// What one quantity means for a sub-service.
  @JsonValue(r'unit')
  unit(r'unit'),

  /// What one quantity means for a sub-service.
  @JsonValue(r'hour')
  hour(r'hour'),

  /// What one quantity means for a sub-service.
  @JsonValue(r'day')
  day(r'day');

  const PriceUnit(this.value);

  final String value;

  @override
  String toString() => value;
}
