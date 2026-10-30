// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_customer_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCustomerSummaryCWProxy {
  AdminCustomerSummary id(String id);

  AdminCustomerSummary name(String name);

  AdminCustomerSummary phone(String? phone);

  AdminCustomerSummary status(AccountStatus status);

  AdminCustomerSummary bookings(int bookings);

  AdminCustomerSummary rating(double? rating);

  AdminCustomerSummary createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCustomerSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCustomerSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminCustomerSummary call({
    String id,
    String name,
    String? phone,
    AccountStatus status,
    int bookings,
    double? rating,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminCustomerSummary.copyWith(...)` or call `instanceOfAdminCustomerSummary.copyWith.fieldName(value)` for a single field.
class _$AdminCustomerSummaryCWProxyImpl
    implements _$AdminCustomerSummaryCWProxy {
  const _$AdminCustomerSummaryCWProxyImpl(this._value);

  final AdminCustomerSummary _value;

  @override
  AdminCustomerSummary id(String id) => call(id: id);

  @override
  AdminCustomerSummary name(String name) => call(name: name);

  @override
  AdminCustomerSummary phone(String? phone) => call(phone: phone);

  @override
  AdminCustomerSummary status(AccountStatus status) => call(status: status);

  @override
  AdminCustomerSummary bookings(int bookings) => call(bookings: bookings);

  @override
  AdminCustomerSummary rating(double? rating) => call(rating: rating);

  @override
  AdminCustomerSummary createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCustomerSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCustomerSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminCustomerSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? bookings = const $CopyWithPlaceholder(),
    Object? rating = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return AdminCustomerSummary(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AccountStatus,
      bookings: bookings == const $CopyWithPlaceholder() || bookings == null
          ? _value.bookings
          // ignore: cast_nullable_to_non_nullable
          : bookings as int,
      rating: rating == const $CopyWithPlaceholder()
          ? _value.rating
          // ignore: cast_nullable_to_non_nullable
          : rating as double?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $AdminCustomerSummaryCopyWith on AdminCustomerSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminCustomerSummary.copyWith(...)` or `instanceOfAdminCustomerSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCustomerSummaryCWProxy get copyWith =>
      _$AdminCustomerSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCustomerSummary _$AdminCustomerSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminCustomerSummary', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name', 'status', 'bookings', 'createdAt'],
  );
  final val = AdminCustomerSummary(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    phone: $checkedConvert('phone', (v) => v as String?),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$AccountStatusEnumMap, v),
    ),
    bookings: $checkedConvert('bookings', (v) => (v as num).toInt()),
    rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$AdminCustomerSummaryToJson(
  AdminCustomerSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': ?instance.phone,
  'status': _$AccountStatusEnumMap[instance.status]!,
  'bookings': instance.bookings,
  'rating': ?instance.rating,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$AccountStatusEnumMap = {
  AccountStatus.pending: 'pending',
  AccountStatus.active: 'active',
  AccountStatus.suspended: 'suspended',
  AccountStatus.banned: 'banned',
};
