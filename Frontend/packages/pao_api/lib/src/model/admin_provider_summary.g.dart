// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_provider_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminProviderSummaryCWProxy {
  AdminProviderSummary id(String id);

  AdminProviderSummary name(String name);

  AdminProviderSummary phone(String? phone);

  AdminProviderSummary status(AccountStatus status);

  AdminProviderSummary level(int level);

  AdminProviderSummary services(List<ServiceRef>? services);

  AdminProviderSummary rating(double rating);

  AdminProviderSummary completedJobs(int completedJobs);

  AdminProviderSummary flaggedForReview(bool flaggedForReview);

  AdminProviderSummary online(bool? online);

  AdminProviderSummary createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminProviderSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminProviderSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminProviderSummary call({
    String id,
    String name,
    String? phone,
    AccountStatus status,
    int level,
    List<ServiceRef>? services,
    double rating,
    int completedJobs,
    bool flaggedForReview,
    bool? online,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminProviderSummary.copyWith(...)` or call `instanceOfAdminProviderSummary.copyWith.fieldName(value)` for a single field.
class _$AdminProviderSummaryCWProxyImpl
    implements _$AdminProviderSummaryCWProxy {
  const _$AdminProviderSummaryCWProxyImpl(this._value);

  final AdminProviderSummary _value;

  @override
  AdminProviderSummary id(String id) => call(id: id);

  @override
  AdminProviderSummary name(String name) => call(name: name);

  @override
  AdminProviderSummary phone(String? phone) => call(phone: phone);

  @override
  AdminProviderSummary status(AccountStatus status) => call(status: status);

  @override
  AdminProviderSummary level(int level) => call(level: level);

  @override
  AdminProviderSummary services(List<ServiceRef>? services) =>
      call(services: services);

  @override
  AdminProviderSummary rating(double rating) => call(rating: rating);

  @override
  AdminProviderSummary completedJobs(int completedJobs) =>
      call(completedJobs: completedJobs);

  @override
  AdminProviderSummary flaggedForReview(bool flaggedForReview) =>
      call(flaggedForReview: flaggedForReview);

  @override
  AdminProviderSummary online(bool? online) => call(online: online);

  @override
  AdminProviderSummary createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminProviderSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminProviderSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminProviderSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? level = const $CopyWithPlaceholder(),
    Object? services = const $CopyWithPlaceholder(),
    Object? rating = const $CopyWithPlaceholder(),
    Object? completedJobs = const $CopyWithPlaceholder(),
    Object? flaggedForReview = const $CopyWithPlaceholder(),
    Object? online = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return AdminProviderSummary(
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
      level: level == const $CopyWithPlaceholder() || level == null
          ? _value.level
          // ignore: cast_nullable_to_non_nullable
          : level as int,
      services: services == const $CopyWithPlaceholder()
          ? _value.services
          // ignore: cast_nullable_to_non_nullable
          : services as List<ServiceRef>?,
      rating: rating == const $CopyWithPlaceholder() || rating == null
          ? _value.rating
          // ignore: cast_nullable_to_non_nullable
          : rating as double,
      completedJobs:
          completedJobs == const $CopyWithPlaceholder() || completedJobs == null
          ? _value.completedJobs
          // ignore: cast_nullable_to_non_nullable
          : completedJobs as int,
      flaggedForReview:
          flaggedForReview == const $CopyWithPlaceholder() ||
              flaggedForReview == null
          ? _value.flaggedForReview
          // ignore: cast_nullable_to_non_nullable
          : flaggedForReview as bool,
      online: online == const $CopyWithPlaceholder()
          ? _value.online
          // ignore: cast_nullable_to_non_nullable
          : online as bool?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $AdminProviderSummaryCopyWith on AdminProviderSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminProviderSummary.copyWith(...)` or `instanceOfAdminProviderSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminProviderSummaryCWProxy get copyWith =>
      _$AdminProviderSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminProviderSummary _$AdminProviderSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminProviderSummary', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'name',
      'status',
      'level',
      'rating',
      'completedJobs',
      'flaggedForReview',
      'createdAt',
    ],
  );
  final val = AdminProviderSummary(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    phone: $checkedConvert('phone', (v) => v as String?),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$AccountStatusEnumMap, v),
    ),
    level: $checkedConvert('level', (v) => (v as num).toInt()),
    services: $checkedConvert(
      'services',
      (v) => (v as List<dynamic>?)
          ?.map((e) => ServiceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    rating: $checkedConvert('rating', (v) => (v as num).toDouble()),
    completedJobs: $checkedConvert('completedJobs', (v) => (v as num).toInt()),
    flaggedForReview: $checkedConvert('flaggedForReview', (v) => v as bool),
    online: $checkedConvert('online', (v) => v as bool?),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$AdminProviderSummaryToJson(
  AdminProviderSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': ?instance.phone,
  'status': _$AccountStatusEnumMap[instance.status]!,
  'level': instance.level,
  'services': ?instance.services?.map((e) => e.toJson()).toList(),
  'rating': instance.rating,
  'completedJobs': instance.completedJobs,
  'flaggedForReview': instance.flaggedForReview,
  'online': ?instance.online,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$AccountStatusEnumMap = {
  AccountStatus.pending: 'pending',
  AccountStatus.active: 'active',
  AccountStatus.suspended: 'suspended',
  AccountStatus.banned: 'banned',
};
