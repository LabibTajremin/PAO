// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_provider_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminProviderDetailCWProxy {
  AdminProviderDetail summary(AdminProviderSummary summary);

  AdminProviderDetail gender(Gender? gender);

  AdminProviderDetail experienceYears(int? experienceYears);

  AdminProviderDetail items(List<VerificationItem> items);

  AdminProviderDetail recentBookings(List<BookingSummary> recentBookings);

  AdminProviderDetail complaints(int? complaints);

  AdminProviderDetail cancellations30d(int? cancellations30d);

  AdminProviderDetail statusHistory(List<AuditEntry> statusHistory);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminProviderDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminProviderDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminProviderDetail call({
    AdminProviderSummary summary,
    Gender? gender,
    int? experienceYears,
    List<VerificationItem> items,
    List<BookingSummary> recentBookings,
    int? complaints,
    int? cancellations30d,
    List<AuditEntry> statusHistory,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminProviderDetail.copyWith(...)` or call `instanceOfAdminProviderDetail.copyWith.fieldName(value)` for a single field.
class _$AdminProviderDetailCWProxyImpl implements _$AdminProviderDetailCWProxy {
  const _$AdminProviderDetailCWProxyImpl(this._value);

  final AdminProviderDetail _value;

  @override
  AdminProviderDetail summary(AdminProviderSummary summary) =>
      call(summary: summary);

  @override
  AdminProviderDetail gender(Gender? gender) => call(gender: gender);

  @override
  AdminProviderDetail experienceYears(int? experienceYears) =>
      call(experienceYears: experienceYears);

  @override
  AdminProviderDetail items(List<VerificationItem> items) => call(items: items);

  @override
  AdminProviderDetail recentBookings(List<BookingSummary> recentBookings) =>
      call(recentBookings: recentBookings);

  @override
  AdminProviderDetail complaints(int? complaints) =>
      call(complaints: complaints);

  @override
  AdminProviderDetail cancellations30d(int? cancellations30d) =>
      call(cancellations30d: cancellations30d);

  @override
  AdminProviderDetail statusHistory(List<AuditEntry> statusHistory) =>
      call(statusHistory: statusHistory);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminProviderDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminProviderDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminProviderDetail call({
    Object? summary = const $CopyWithPlaceholder(),
    Object? gender = const $CopyWithPlaceholder(),
    Object? experienceYears = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? recentBookings = const $CopyWithPlaceholder(),
    Object? complaints = const $CopyWithPlaceholder(),
    Object? cancellations30d = const $CopyWithPlaceholder(),
    Object? statusHistory = const $CopyWithPlaceholder(),
  }) {
    return AdminProviderDetail(
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as AdminProviderSummary,
      gender: gender == const $CopyWithPlaceholder()
          ? _value.gender
          // ignore: cast_nullable_to_non_nullable
          : gender as Gender?,
      experienceYears: experienceYears == const $CopyWithPlaceholder()
          ? _value.experienceYears
          // ignore: cast_nullable_to_non_nullable
          : experienceYears as int?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<VerificationItem>,
      recentBookings:
          recentBookings == const $CopyWithPlaceholder() ||
              recentBookings == null
          ? _value.recentBookings
          // ignore: cast_nullable_to_non_nullable
          : recentBookings as List<BookingSummary>,
      complaints: complaints == const $CopyWithPlaceholder()
          ? _value.complaints
          // ignore: cast_nullable_to_non_nullable
          : complaints as int?,
      cancellations30d: cancellations30d == const $CopyWithPlaceholder()
          ? _value.cancellations30d
          // ignore: cast_nullable_to_non_nullable
          : cancellations30d as int?,
      statusHistory:
          statusHistory == const $CopyWithPlaceholder() || statusHistory == null
          ? _value.statusHistory
          // ignore: cast_nullable_to_non_nullable
          : statusHistory as List<AuditEntry>,
    );
  }
}

extension $AdminProviderDetailCopyWith on AdminProviderDetail {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminProviderDetail.copyWith(...)` or `instanceOfAdminProviderDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminProviderDetailCWProxy get copyWith =>
      _$AdminProviderDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminProviderDetail _$AdminProviderDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminProviderDetail', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'summary',
          'items',
          'recentBookings',
          'statusHistory',
        ],
      );
      final val = AdminProviderDetail(
        summary: $checkedConvert(
          'summary',
          (v) => AdminProviderSummary.fromJson(v as Map<String, dynamic>),
        ),
        gender: $checkedConvert(
          'gender',
          (v) => $enumDecodeNullable(_$GenderEnumMap, v),
        ),
        experienceYears: $checkedConvert(
          'experienceYears',
          (v) => (v as num?)?.toInt(),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => VerificationItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        recentBookings: $checkedConvert(
          'recentBookings',
          (v) => (v as List<dynamic>)
              .map((e) => BookingSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        complaints: $checkedConvert('complaints', (v) => (v as num?)?.toInt()),
        cancellations30d: $checkedConvert(
          'cancellations30d',
          (v) => (v as num?)?.toInt(),
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

Map<String, dynamic> _$AdminProviderDetailToJson(
  AdminProviderDetail instance,
) => <String, dynamic>{
  'summary': instance.summary.toJson(),
  'gender': ?_$GenderEnumMap[instance.gender],
  'experienceYears': ?instance.experienceYears,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'recentBookings': instance.recentBookings.map((e) => e.toJson()).toList(),
  'complaints': ?instance.complaints,
  'cancellations30d': ?instance.cancellations30d,
  'statusHistory': instance.statusHistory.map((e) => e.toJson()).toList(),
};

const _$GenderEnumMap = {
  Gender.female: 'female',
  Gender.male: 'male',
  Gender.other: 'other',
};
