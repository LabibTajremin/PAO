//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
enum DeliveryStatus {
  /// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
  @JsonValue(r'scheduled')
  scheduled(r'scheduled'),

  /// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
  @JsonValue(r'preparing')
  preparing(r'preparing'),

  /// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
  @JsonValue(r'out_for_delivery')
  outForDelivery(r'out_for_delivery'),

  /// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
  @JsonValue(r'delivered')
  delivered(r'delivered'),

  /// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
  @JsonValue(r'skipped')
  skipped(r'skipped'),

  /// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
  @JsonValue(r'declined')
  declined(r'declined'),

  /// Derived: scheduled until the cutoff sweep makes a booking, then the booking's progress.
  @JsonValue(r'cancelled')
  cancelled(r'cancelled');

  const DeliveryStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
