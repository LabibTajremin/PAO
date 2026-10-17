// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerificationItemCWProxy {
  VerificationItem type(ItemType type);

  VerificationItem status(ItemStatus status);

  VerificationItem required_(bool required_);

  VerificationItem rejectionReason(String? rejectionReason);

  VerificationItem expiresAt(DateTime? expiresAt);

  VerificationItem decidedAt(DateTime? decidedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationItem(...).copyWith(id: 12, name: "My name")
  /// ```
  VerificationItem call({
    ItemType type,
    ItemStatus status,
    bool required_,
    String? rejectionReason,
    DateTime? expiresAt,
    DateTime? decidedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVerificationItem.copyWith(...)` or call `instanceOfVerificationItem.copyWith.fieldName(value)` for a single field.
class _$VerificationItemCWProxyImpl implements _$VerificationItemCWProxy {
  const _$VerificationItemCWProxyImpl(this._value);

  final VerificationItem _value;

  @override
  VerificationItem type(ItemType type) => call(type: type);

  @override
  VerificationItem status(ItemStatus status) => call(status: status);

  @override
  VerificationItem required_(bool required_) => call(required_: required_);

  @override
  VerificationItem rejectionReason(String? rejectionReason) =>
      call(rejectionReason: rejectionReason);

  @override
  VerificationItem expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  VerificationItem decidedAt(DateTime? decidedAt) => call(decidedAt: decidedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VerificationItem call({
    Object? type = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? required_ = const $CopyWithPlaceholder(),
    Object? rejectionReason = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? decidedAt = const $CopyWithPlaceholder(),
  }) {
    return VerificationItem(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ItemType,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ItemStatus,
      required_: required_ == const $CopyWithPlaceholder() || required_ == null
          ? _value.required_
          // ignore: cast_nullable_to_non_nullable
          : required_ as bool,
      rejectionReason: rejectionReason == const $CopyWithPlaceholder()
          ? _value.rejectionReason
          // ignore: cast_nullable_to_non_nullable
          : rejectionReason as String?,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      decidedAt: decidedAt == const $CopyWithPlaceholder()
          ? _value.decidedAt
          // ignore: cast_nullable_to_non_nullable
          : decidedAt as DateTime?,
    );
  }
}

extension $VerificationItemCopyWith on VerificationItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVerificationItem.copyWith(...)` or `instanceOfVerificationItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerificationItemCWProxy get copyWith => _$VerificationItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationItem _$VerificationItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VerificationItem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['type', 'status', 'required']);
      final val = VerificationItem(
        type: $checkedConvert('type', (v) => $enumDecode(_$ItemTypeEnumMap, v)),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$ItemStatusEnumMap, v),
        ),
        required_: $checkedConvert('required', (v) => v as bool),
        rejectionReason: $checkedConvert(
          'rejectionReason',
          (v) => v as String?,
        ),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        decidedAt: $checkedConvert(
          'decidedAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'required_': 'required'});

Map<String, dynamic> _$VerificationItemToJson(VerificationItem instance) =>
    <String, dynamic>{
      'type': _$ItemTypeEnumMap[instance.type]!,
      'status': _$ItemStatusEnumMap[instance.status]!,
      'required': instance.required_,
      'rejectionReason': ?instance.rejectionReason,
      'expiresAt': ?instance.expiresAt?.toIso8601String(),
      'decidedAt': ?instance.decidedAt?.toIso8601String(),
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

const _$ItemStatusEnumMap = {
  ItemStatus.missing: 'missing',
  ItemStatus.pending: 'pending',
  ItemStatus.approved: 'approved',
  ItemStatus.rejected: 'rejected',
  ItemStatus.expired: 'expired',
};
