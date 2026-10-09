// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComplaintCWProxy {
  Complaint id(String id);

  Complaint ticketNumber(String ticketNumber);

  Complaint bookingId(String bookingId);

  Complaint reporterRole(ComplaintReporterRoleEnum reporterRole);

  Complaint reporterId(String reporterId);

  Complaint againstId(String? againstId);

  Complaint reason(ComplaintReason reason);

  Complaint description(String description);

  Complaint photoMediaIds(List<String>? photoMediaIds);

  Complaint status(ComplaintStatus status);

  Complaint assigneeId(String? assigneeId);

  Complaint resolution(String? resolution);

  Complaint verified(bool? verified);

  Complaint comments(List<ComplaintComment>? comments);

  Complaint createdAt(DateTime createdAt);

  Complaint resolvedAt(DateTime? resolvedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Complaint(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Complaint(...).copyWith(id: 12, name: "My name")
  /// ```
  Complaint call({
    String id,
    String ticketNumber,
    String bookingId,
    ComplaintReporterRoleEnum reporterRole,
    String reporterId,
    String? againstId,
    ComplaintReason reason,
    String description,
    List<String>? photoMediaIds,
    ComplaintStatus status,
    String? assigneeId,
    String? resolution,
    bool? verified,
    List<ComplaintComment>? comments,
    DateTime createdAt,
    DateTime? resolvedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComplaint.copyWith(...)` or call `instanceOfComplaint.copyWith.fieldName(value)` for a single field.
class _$ComplaintCWProxyImpl implements _$ComplaintCWProxy {
  const _$ComplaintCWProxyImpl(this._value);

  final Complaint _value;

  @override
  Complaint id(String id) => call(id: id);

  @override
  Complaint ticketNumber(String ticketNumber) =>
      call(ticketNumber: ticketNumber);

  @override
  Complaint bookingId(String bookingId) => call(bookingId: bookingId);

  @override
  Complaint reporterRole(ComplaintReporterRoleEnum reporterRole) =>
      call(reporterRole: reporterRole);

  @override
  Complaint reporterId(String reporterId) => call(reporterId: reporterId);

  @override
  Complaint againstId(String? againstId) => call(againstId: againstId);

  @override
  Complaint reason(ComplaintReason reason) => call(reason: reason);

  @override
  Complaint description(String description) => call(description: description);

  @override
  Complaint photoMediaIds(List<String>? photoMediaIds) =>
      call(photoMediaIds: photoMediaIds);

  @override
  Complaint status(ComplaintStatus status) => call(status: status);

  @override
  Complaint assigneeId(String? assigneeId) => call(assigneeId: assigneeId);

  @override
  Complaint resolution(String? resolution) => call(resolution: resolution);

  @override
  Complaint verified(bool? verified) => call(verified: verified);

  @override
  Complaint comments(List<ComplaintComment>? comments) =>
      call(comments: comments);

  @override
  Complaint createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  Complaint resolvedAt(DateTime? resolvedAt) => call(resolvedAt: resolvedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Complaint(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Complaint(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Complaint call({
    Object? id = const $CopyWithPlaceholder(),
    Object? ticketNumber = const $CopyWithPlaceholder(),
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? reporterRole = const $CopyWithPlaceholder(),
    Object? reporterId = const $CopyWithPlaceholder(),
    Object? againstId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? photoMediaIds = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? assigneeId = const $CopyWithPlaceholder(),
    Object? resolution = const $CopyWithPlaceholder(),
    Object? verified = const $CopyWithPlaceholder(),
    Object? comments = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? resolvedAt = const $CopyWithPlaceholder(),
  }) {
    return Complaint(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      ticketNumber:
          ticketNumber == const $CopyWithPlaceholder() || ticketNumber == null
          ? _value.ticketNumber
          // ignore: cast_nullable_to_non_nullable
          : ticketNumber as String,
      bookingId: bookingId == const $CopyWithPlaceholder() || bookingId == null
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String,
      reporterRole:
          reporterRole == const $CopyWithPlaceholder() || reporterRole == null
          ? _value.reporterRole
          // ignore: cast_nullable_to_non_nullable
          : reporterRole as ComplaintReporterRoleEnum,
      reporterId:
          reporterId == const $CopyWithPlaceholder() || reporterId == null
          ? _value.reporterId
          // ignore: cast_nullable_to_non_nullable
          : reporterId as String,
      againstId: againstId == const $CopyWithPlaceholder()
          ? _value.againstId
          // ignore: cast_nullable_to_non_nullable
          : againstId as String?,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as ComplaintReason,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      photoMediaIds: photoMediaIds == const $CopyWithPlaceholder()
          ? _value.photoMediaIds
          // ignore: cast_nullable_to_non_nullable
          : photoMediaIds as List<String>?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ComplaintStatus,
      assigneeId: assigneeId == const $CopyWithPlaceholder()
          ? _value.assigneeId
          // ignore: cast_nullable_to_non_nullable
          : assigneeId as String?,
      resolution: resolution == const $CopyWithPlaceholder()
          ? _value.resolution
          // ignore: cast_nullable_to_non_nullable
          : resolution as String?,
      verified: verified == const $CopyWithPlaceholder()
          ? _value.verified
          // ignore: cast_nullable_to_non_nullable
          : verified as bool?,
      comments: comments == const $CopyWithPlaceholder()
          ? _value.comments
          // ignore: cast_nullable_to_non_nullable
          : comments as List<ComplaintComment>?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      resolvedAt: resolvedAt == const $CopyWithPlaceholder()
          ? _value.resolvedAt
          // ignore: cast_nullable_to_non_nullable
          : resolvedAt as DateTime?,
    );
  }
}

extension $ComplaintCopyWith on Complaint {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComplaint.copyWith(...)` or `instanceOfComplaint.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComplaintCWProxy get copyWith => _$ComplaintCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Complaint _$ComplaintFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Complaint', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'ticketNumber',
          'bookingId',
          'reporterRole',
          'reporterId',
          'reason',
          'description',
          'status',
          'createdAt',
        ],
      );
      final val = Complaint(
        id: $checkedConvert('id', (v) => v as String),
        ticketNumber: $checkedConvert('ticketNumber', (v) => v as String),
        bookingId: $checkedConvert('bookingId', (v) => v as String),
        reporterRole: $checkedConvert(
          'reporterRole',
          (v) => $enumDecode(_$ComplaintReporterRoleEnumEnumMap, v),
        ),
        reporterId: $checkedConvert('reporterId', (v) => v as String),
        againstId: $checkedConvert('againstId', (v) => v as String?),
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$ComplaintReasonEnumMap, v),
        ),
        description: $checkedConvert('description', (v) => v as String),
        photoMediaIds: $checkedConvert(
          'photoMediaIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$ComplaintStatusEnumMap, v),
        ),
        assigneeId: $checkedConvert('assigneeId', (v) => v as String?),
        resolution: $checkedConvert('resolution', (v) => v as String?),
        verified: $checkedConvert('verified', (v) => v as bool?),
        comments: $checkedConvert(
          'comments',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ComplaintComment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        resolvedAt: $checkedConvert(
          'resolvedAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ComplaintToJson(Complaint instance) => <String, dynamic>{
  'id': instance.id,
  'ticketNumber': instance.ticketNumber,
  'bookingId': instance.bookingId,
  'reporterRole': _$ComplaintReporterRoleEnumEnumMap[instance.reporterRole]!,
  'reporterId': instance.reporterId,
  'againstId': ?instance.againstId,
  'reason': _$ComplaintReasonEnumMap[instance.reason]!,
  'description': instance.description,
  'photoMediaIds': ?instance.photoMediaIds,
  'status': _$ComplaintStatusEnumMap[instance.status]!,
  'assigneeId': ?instance.assigneeId,
  'resolution': ?instance.resolution,
  'verified': ?instance.verified,
  'comments': ?instance.comments?.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'resolvedAt': ?instance.resolvedAt?.toIso8601String(),
};

const _$ComplaintReporterRoleEnumEnumMap = {
  ComplaintReporterRoleEnum.customer: 'customer',
  ComplaintReporterRoleEnum.provider: 'provider',
};

const _$ComplaintReasonEnumMap = {
  ComplaintReason.noShow: 'no_show',
  ComplaintReason.late_: 'late',
  ComplaintReason.poorQuality: 'poor_quality',
  ComplaintReason.overcharge: 'overcharge',
  ComplaintReason.damage: 'damage',
  ComplaintReason.behaviour: 'behaviour',
  ComplaintReason.safety: 'safety',
  ComplaintReason.customerUnavailable: 'customer_unavailable',
  ComplaintReason.payment: 'payment',
  ComplaintReason.other: 'other',
};

const _$ComplaintStatusEnumMap = {
  ComplaintStatus.open: 'open',
  ComplaintStatus.assigned: 'assigned',
  ComplaintStatus.resolved: 'resolved',
};
