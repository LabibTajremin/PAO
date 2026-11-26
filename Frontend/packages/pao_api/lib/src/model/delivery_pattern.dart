//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// How the dates repeat; `weekdays` and `weekly` use `weekdays`, `monthly` uses `dayOfMonth`.
enum DeliveryPattern {
  /// How the dates repeat; `weekdays` and `weekly` use `weekdays`, `monthly` uses `dayOfMonth`.
  @JsonValue(r'once')
  once(r'once'),

  /// How the dates repeat; `weekdays` and `weekly` use `weekdays`, `monthly` uses `dayOfMonth`.
  @JsonValue(r'daily')
  daily(r'daily'),

  /// How the dates repeat; `weekdays` and `weekly` use `weekdays`, `monthly` uses `dayOfMonth`.
  @JsonValue(r'weekdays')
  weekdays(r'weekdays'),

  /// How the dates repeat; `weekdays` and `weekly` use `weekdays`, `monthly` uses `dayOfMonth`.
  @JsonValue(r'weekly')
  weekly(r'weekly'),

  /// How the dates repeat; `weekdays` and `weekly` use `weekdays`, `monthly` uses `dayOfMonth`.
  @JsonValue(r'monthly')
  monthly(r'monthly');

  const DeliveryPattern(this.value);

  final String value;

  @override
  String toString() => value;
}
