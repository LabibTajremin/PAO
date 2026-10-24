// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_queue_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerificationQueueItemCWProxy {
  VerificationQueueItem providerId(String providerId);

  VerificationQueueItem name(String name);

  VerificationQueueItem services(List<ServiceRef>? services);

  VerificationQueueItem pendingItems(List<ItemType> pendingItems);

  VerificationQueueItem submittedAt(DateTime submittedAt);

  VerificationQueueItem ageHours(int ageHours);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationQueueItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationQueueItem(...).copyWith(id: 12, name: "My name")
  /// ```
  VerificationQueueItem call({
    String providerId,
    String name,
    List<ServiceRef>? services,
    List<ItemType> pendingItems,
    DateTime submittedAt,
    int ageHours,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVerificationQueueItem.copyWith(...)` or call `instanceOfVerificationQueueItem.copyWith.fieldName(value)` for a single field.
class _$VerificationQueueItemCWProxyImpl
    implements _$VerificationQueueItemCWProxy {
  const _$VerificationQueueItemCWProxyImpl(this._value);

  final VerificationQueueItem _value;

  @override
  VerificationQueueItem providerId(String providerId) =>
      call(providerId: providerId);

  @override
  VerificationQueueItem name(String name) => call(name: name);

  @override
  VerificationQueueItem services(List<ServiceRef>? services) =>
      call(services: services);

  @override
  VerificationQueueItem pendingItems(List<ItemType> pendingItems) =>
      call(pendingItems: pendingItems);

  @override
  VerificationQueueItem submittedAt(DateTime submittedAt) =>
      call(submittedAt: submittedAt);

  @override
  VerificationQueueItem ageHours(int ageHours) => call(ageHours: ageHours);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationQueueItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationQueueItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VerificationQueueItem call({
    Object? providerId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? services = const $CopyWithPlaceholder(),
    Object? pendingItems = const $CopyWithPlaceholder(),
    Object? submittedAt = const $CopyWithPlaceholder(),
    Object? ageHours = const $CopyWithPlaceholder(),
  }) {
    return VerificationQueueItem(
      providerId:
          providerId == const $CopyWithPlaceholder() || providerId == null
          ? _value.providerId
          // ignore: cast_nullable_to_non_nullable
          : providerId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      services: services == const $CopyWithPlaceholder()
          ? _value.services
          // ignore: cast_nullable_to_non_nullable
          : services as List<ServiceRef>?,
      pendingItems:
          pendingItems == const $CopyWithPlaceholder() || pendingItems == null
          ? _value.pendingItems
          // ignore: cast_nullable_to_non_nullable
          : pendingItems as List<ItemType>,
      submittedAt:
          submittedAt == const $CopyWithPlaceholder() || submittedAt == null
          ? _value.submittedAt
          // ignore: cast_nullable_to_non_nullable
          : submittedAt as DateTime,
      ageHours: ageHours == const $CopyWithPlaceholder() || ageHours == null
          ? _value.ageHours
          // ignore: cast_nullable_to_non_nullable
          : ageHours as int,
    );
  }
}

extension $VerificationQueueItemCopyWith on VerificationQueueItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVerificationQueueItem.copyWith(...)` or `instanceOfVerificationQueueItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerificationQueueItemCWProxy get copyWith =>
      _$VerificationQueueItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationQueueItem _$VerificationQueueItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VerificationQueueItem', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'providerId',
      'name',
      'pendingItems',
      'submittedAt',
      'ageHours',
    ],
  );
  final val = VerificationQueueItem(
    providerId: $checkedConvert('providerId', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    services: $checkedConvert(
      'services',
      (v) => (v as List<dynamic>?)
          ?.map((e) => ServiceRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    pendingItems: $checkedConvert(
      'pendingItems',
      (v) => (v as List<dynamic>)
          .map((e) => $enumDecode(_$ItemTypeEnumMap, e))
          .toList(),
    ),
    submittedAt: $checkedConvert(
      'submittedAt',
      (v) => DateTime.parse(v as String),
    ),
    ageHours: $checkedConvert('ageHours', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$VerificationQueueItemToJson(
  VerificationQueueItem instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
  'name': instance.name,
  'services': ?instance.services?.map((e) => e.toJson()).toList(),
  'pendingItems': instance.pendingItems
      .map((e) => _$ItemTypeEnumMap[e]!)
      .toList(),
  'submittedAt': instance.submittedAt.toIso8601String(),
  'ageHours': instance.ageHours,
};

const _$ItemTypeEnumMap = {
  ItemType.nid: 'nid',
  ItemType.selfie: 'selfie',
  ItemType.policeClearance: 'police_clearance',
  ItemType.address: 'address',
  ItemType.emergencyContact: 'emergency_contact',
  ItemType.skillProof: 'skill_proof',
  ItemType.serviceArea: 'service_area',
  ItemType.codeOfConduct: 'code_of_conduct',
};
