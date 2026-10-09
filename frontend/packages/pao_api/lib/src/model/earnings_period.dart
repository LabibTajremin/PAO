//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum EarningsPeriod {
  @JsonValue(r'day')
  day(r'day'),
  @JsonValue(r'week')
  week(r'week'),
  @JsonValue(r'month')
  month(r'month');

  const EarningsPeriod(this.value);

  final String value;

  @override
  String toString() => value;
}
