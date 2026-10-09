//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_summary.dart';
import 'package:pao_api/src/model/complaint.dart';
import 'package:pao_api/src/model/admin_customer_summary.dart';
import 'package:pao_api/src/model/audit_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_customer_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCustomerDetail {
  /// Returns a new [AdminCustomerDetail] instance.
  AdminCustomerDetail({
    required this.summary,

    required this.recentBookings,

    required this.complaints,

    required this.statusHistory,
  });

  @JsonKey(name: r'summary', required: true, includeIfNull: false)
  final AdminCustomerSummary summary;

  @JsonKey(name: r'recentBookings', required: true, includeIfNull: false)
  final List<BookingSummary> recentBookings;

  @JsonKey(name: r'complaints', required: true, includeIfNull: false)
  final List<Complaint> complaints;

  @JsonKey(name: r'statusHistory', required: true, includeIfNull: false)
  final List<AuditEntry> statusHistory;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminCustomerDetail &&
            runtimeType == other.runtimeType &&
            equals(
              [summary, recentBookings, complaints, statusHistory],
              [
                other.summary,
                other.recentBookings,
                other.complaints,
                other.statusHistory,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([summary, recentBookings, complaints, statusHistory]);

  factory AdminCustomerDetail.fromJson(Map<String, dynamic> json) =>
      _$AdminCustomerDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCustomerDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
