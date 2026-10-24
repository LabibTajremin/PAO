//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/verification_item.dart';
import 'package:pao_api/src/model/booking_summary.dart';
import 'package:pao_api/src/model/admin_provider_summary.dart';
import 'package:pao_api/src/model/audit_entry.dart';
import 'package:pao_api/src/model/gender.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_provider_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminProviderDetail {
  /// Returns a new [AdminProviderDetail] instance.
  AdminProviderDetail({
    required this.summary,

    this.gender,

    this.experienceYears,

    required this.items,

    required this.recentBookings,

    this.complaints,

    this.cancellations30d,

    required this.statusHistory,
  });

  @JsonKey(name: r'summary', required: true, includeIfNull: false)
  final AdminProviderSummary summary;

  @JsonKey(name: r'gender', required: false, includeIfNull: false)
  final Gender? gender;

  @JsonKey(name: r'experienceYears', required: false, includeIfNull: false)
  final int? experienceYears;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<VerificationItem> items;

  @JsonKey(name: r'recentBookings', required: true, includeIfNull: false)
  final List<BookingSummary> recentBookings;

  @JsonKey(name: r'complaints', required: false, includeIfNull: false)
  final int? complaints;

  @JsonKey(name: r'cancellations30d', required: false, includeIfNull: false)
  final int? cancellations30d;

  @JsonKey(name: r'statusHistory', required: true, includeIfNull: false)
  final List<AuditEntry> statusHistory;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminProviderDetail &&
            runtimeType == other.runtimeType &&
            equals(
              [
                summary,
                gender,
                experienceYears,
                items,
                recentBookings,
                complaints,
                cancellations30d,
                statusHistory,
              ],
              [
                other.summary,
                other.gender,
                other.experienceYears,
                other.items,
                other.recentBookings,
                other.complaints,
                other.cancellations30d,
                other.statusHistory,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        summary,
        gender,
        experienceYears,
        items,
        recentBookings,
        complaints,
        cancellations30d,
        statusHistory,
      ]);

  factory AdminProviderDetail.fromJson(Map<String, dynamic> json) =>
      _$AdminProviderDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AdminProviderDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
