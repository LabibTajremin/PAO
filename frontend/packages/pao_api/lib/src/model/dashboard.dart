//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/dashboard_bookings_per_day_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'dashboard.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Dashboard {
  /// Returns a new [Dashboard] instance.
  Dashboard({
    required this.providersByStatus,

    required this.providersByLevel,

    required this.bookingsPerDay,

    required this.completionRate,

    required this.openComplaints,

    required this.pendingVerifications,

    required this.generatedAt,
  });

  @JsonKey(name: r'providersByStatus', required: true, includeIfNull: false)
  final Map<String, int> providersByStatus;

  @JsonKey(name: r'providersByLevel', required: true, includeIfNull: false)
  final Map<String, int> providersByLevel;

  @JsonKey(name: r'bookingsPerDay', required: true, includeIfNull: false)
  final List<DashboardBookingsPerDayInner> bookingsPerDay;

  @JsonKey(name: r'completionRate', required: true, includeIfNull: false)
  final double completionRate;

  @JsonKey(name: r'openComplaints', required: true, includeIfNull: false)
  final int openComplaints;

  @JsonKey(name: r'pendingVerifications', required: true, includeIfNull: false)
  final int pendingVerifications;

  @JsonKey(name: r'generatedAt', required: true, includeIfNull: false)
  final DateTime generatedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Dashboard &&
            runtimeType == other.runtimeType &&
            equals(
              [
                providersByStatus,
                providersByLevel,
                bookingsPerDay,
                completionRate,
                openComplaints,
                pendingVerifications,
                generatedAt,
              ],
              [
                other.providersByStatus,
                other.providersByLevel,
                other.bookingsPerDay,
                other.completionRate,
                other.openComplaints,
                other.pendingVerifications,
                other.generatedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        providersByStatus,
        providersByLevel,
        bookingsPerDay,
        completionRate,
        openComplaints,
        pendingVerifications,
        generatedAt,
      ]);

  factory Dashboard.fromJson(Map<String, dynamic> json) =>
      _$DashboardFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
