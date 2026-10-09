//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/complaint_comment.dart';
import 'package:pao_api/src/model/complaint_status.dart';
import 'package:pao_api/src/model/complaint_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complaint.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Complaint {
  /// Returns a new [Complaint] instance.
  Complaint({
    required this.id,

    required this.ticketNumber,

    required this.bookingId,

    required this.reporterRole,

    required this.reporterId,

    this.againstId,

    required this.reason,

    required this.description,

    this.photoMediaIds,

    required this.status,

    this.assigneeId,

    this.resolution,

    this.verified,

    this.comments,

    required this.createdAt,

    this.resolvedAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'ticketNumber', required: true, includeIfNull: false)
  final String ticketNumber;

  @JsonKey(name: r'bookingId', required: true, includeIfNull: false)
  final String bookingId;

  @JsonKey(name: r'reporterRole', required: true, includeIfNull: false)
  final ComplaintReporterRoleEnum reporterRole;

  @JsonKey(name: r'reporterId', required: true, includeIfNull: false)
  final String reporterId;

  @JsonKey(name: r'againstId', required: false, includeIfNull: false)
  final String? againstId;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final ComplaintReason reason;

  @JsonKey(name: r'description', required: true, includeIfNull: false)
  final String description;

  @JsonKey(name: r'photoMediaIds', required: false, includeIfNull: false)
  final List<String>? photoMediaIds;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ComplaintStatus status;

  @JsonKey(name: r'assigneeId', required: false, includeIfNull: false)
  final String? assigneeId;

  @JsonKey(name: r'resolution', required: false, includeIfNull: false)
  final String? resolution;

  /// A verified complaint feeds the provider quality review (PRD §6.4).
  @JsonKey(name: r'verified', required: false, includeIfNull: false)
  final bool? verified;

  @JsonKey(name: r'comments', required: false, includeIfNull: false)
  final List<ComplaintComment>? comments;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'resolvedAt', required: false, includeIfNull: false)
  final DateTime? resolvedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Complaint &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                ticketNumber,
                bookingId,
                reporterRole,
                reporterId,
                againstId,
                reason,
                description,
                photoMediaIds,
                status,
                assigneeId,
                resolution,
                verified,
                comments,
                createdAt,
                resolvedAt,
              ],
              [
                other.id,
                other.ticketNumber,
                other.bookingId,
                other.reporterRole,
                other.reporterId,
                other.againstId,
                other.reason,
                other.description,
                other.photoMediaIds,
                other.status,
                other.assigneeId,
                other.resolution,
                other.verified,
                other.comments,
                other.createdAt,
                other.resolvedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        ticketNumber,
        bookingId,
        reporterRole,
        reporterId,
        againstId,
        reason,
        description,
        photoMediaIds,
        status,
        assigneeId,
        resolution,
        verified,
        comments,
        createdAt,
        resolvedAt,
      ]);

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ComplaintReporterRoleEnum {
  @JsonValue(r'customer')
  customer(r'customer'),
  @JsonValue(r'provider')
  provider(r'provider');

  const ComplaintReporterRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
