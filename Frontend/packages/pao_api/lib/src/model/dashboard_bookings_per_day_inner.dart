//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'dashboard_bookings_per_day_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DashboardBookingsPerDayInner {
  /// Returns a new [DashboardBookingsPerDayInner] instance.
  DashboardBookingsPerDayInner({
    required this.date,

    required this.total,

    required this.completed,
  });

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final String date;

  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'completed', required: true, includeIfNull: false)
  final int completed;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DashboardBookingsPerDayInner &&
            runtimeType == other.runtimeType &&
            equals(
              [date, total, completed],
              [other.date, other.total, other.completed],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([date, total, completed]);

  factory DashboardBookingsPerDayInner.fromJson(Map<String, dynamic> json) =>
      _$DashboardBookingsPerDayInnerFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardBookingsPerDayInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
