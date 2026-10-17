// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_customer_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCustomerDetailCWProxy {
  AdminCustomerDetail summary(AdminCustomerSummary summary);

  AdminCustomerDetail recentBookings(List<BookingSummary> recentBookings);

  AdminCustomerDetail complaints(List<Complaint> complaints);

  AdminCustomerDetail statusHistory(List<AuditEntry> statusHistory);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCustomerDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCustomerDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminCustomerDetail call({
    AdminCustomerSummary summary,
    List<BookingSummary> recentBookings,
    List<Complaint> complaints,
    List<AuditEntry> statusHistory,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminCustomerDetail.copyWith(...)` or call `instanceOfAdminCustomerDetail.copyWith.fieldName(value)` for a single field.
class _$AdminCustomerDetailCWProxyImpl implements _$AdminCustomerDetailCWProxy {
  const _$AdminCustomerDetailCWProxyImpl(this._value);

  final AdminCustomerDetail _value;

  @override
  AdminCustomerDetail summary(AdminCustomerSummary summary) =>
      call(summary: summary);

  @override
  AdminCustomerDetail recentBookings(List<BookingSummary> recentBookings) =>
      call(recentBookings: recentBookings);

  @override
  AdminCustomerDetail complaints(List<Complaint> complaints) =>
      call(complaints: complaints);

  @override
  AdminCustomerDetail statusHistory(List<AuditEntry> statusHistory) =>
      call(statusHistory: statusHistory);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCustomerDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCustomerDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminCustomerDetail call({
    Object? summary = const $CopyWithPlaceholder(),
    Object? recentBookings = const $CopyWithPlaceholder(),
    Object? complaints = const $CopyWithPlaceholder(),
    Object? statusHistory = const $CopyWithPlaceholder(),
  }) {
    return AdminCustomerDetail(
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as AdminCustomerSummary,
      recentBookings:
          recentBookings == const $CopyWithPlaceholder() ||
              recentBookings == null
          ? _value.recentBookings
          // ignore: cast_nullable_to_non_nullable
          : recentBookings as List<BookingSummary>,
      complaints:
          complaints == const $CopyWithPlaceholder() || complaints == null
          ? _value.complaints
          // ignore: cast_nullable_to_non_nullable
          : complaints as List<Complaint>,
      statusHistory:
          statusHistory == const $CopyWithPlaceholder() || statusHistory == null
          ? _value.statusHistory
          // ignore: cast_nullable_to_non_nullable
          : statusHistory as List<AuditEntry>,
    );
  }
}

extension $AdminCustomerDetailCopyWith on AdminCustomerDetail {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminCustomerDetail.copyWith(...)` or `instanceOfAdminCustomerDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCustomerDetailCWProxy get copyWith =>
      _$AdminCustomerDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCustomerDetail _$AdminCustomerDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCustomerDetail', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'summary',
          'recentBookings',
          'complaints',
          'statusHistory',
        ],
      );
      final val = AdminCustomerDetail(
        summary: $checkedConvert(
          'summary',
          (v) => AdminCustomerSummary.fromJson(v as Map<String, dynamic>),
        ),
        recentBookings: $checkedConvert(
          'recentBookings',
          (v) => (v as List<dynamic>)
              .map((e) => BookingSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        complaints: $checkedConvert(
          'complaints',
          (v) => (v as List<dynamic>)
              .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        statusHistory: $checkedConvert(
          'statusHistory',
          (v) => (v as List<dynamic>)
              .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminCustomerDetailToJson(
  AdminCustomerDetail instance,
) => <String, dynamic>{
  'summary': instance.summary.toJson(),
  'recentBookings': instance.recentBookings.map((e) => e.toJson()).toList(),
  'complaints': instance.complaints.map((e) => e.toJson()).toList(),
  'statusHistory': instance.statusHistory.map((e) => e.toJson()).toList(),
};
