// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewItemCWProxy {
  ReviewItem type(ItemType type);

  ReviewItem status(ItemStatus status);

  ReviewItem required_(bool required_);

  ReviewItem rejectionReason(String? rejectionReason);

  ReviewItem expiresAt(DateTime? expiresAt);

  ReviewItem decidedAt(DateTime? decidedAt);

  ReviewItem documents(List<ReviewDocument>? documents);

  ReviewItem fields(Map<String, String>? fields);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewItem(...).copyWith(id: 12, name: "My name")
  /// ```
  ReviewItem call({
    ItemType type,
    ItemStatus status,
    bool required_,
    String? rejectionReason,
    DateTime? expiresAt,
    DateTime? decidedAt,
    List<ReviewDocument>? documents,
    Map<String, String>? fields,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReviewItem.copyWith(...)` or call `instanceOfReviewItem.copyWith.fieldName(value)` for a single field.
class _$ReviewItemCWProxyImpl implements _$ReviewItemCWProxy {
  const _$ReviewItemCWProxyImpl(this._value);

  final ReviewItem _value;

  @override
  ReviewItem type(ItemType type) => call(type: type);

  @override
  ReviewItem status(ItemStatus status) => call(status: status);

  @override
  ReviewItem required_(bool required_) => call(required_: required_);

  @override
  ReviewItem rejectionReason(String? rejectionReason) =>
      call(rejectionReason: rejectionReason);

  @override
  ReviewItem expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  ReviewItem decidedAt(DateTime? decidedAt) => call(decidedAt: decidedAt);

  @override
  ReviewItem documents(List<ReviewDocument>? documents) =>
      call(documents: documents);

  @override
  ReviewItem fields(Map<String, String>? fields) => call(fields: fields);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReviewItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReviewItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReviewItem call({
    Object? type = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? required_ = const $CopyWithPlaceholder(),
    Object? rejectionReason = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? decidedAt = const $CopyWithPlaceholder(),
    Object? documents = const $CopyWithPlaceholder(),
    Object? fields = const $CopyWithPlaceholder(),
  }) {
    return ReviewItem(
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
      documents: documents == const $CopyWithPlaceholder()
          ? _value.documents
          // ignore: cast_nullable_to_non_nullable
          : documents as List<ReviewDocument>?,
      fields: fields == const $CopyWithPlaceholder()
          ? _value.fields
          // ignore: cast_nullable_to_non_nullable
          : fields as Map<String, String>?,
    );
  }
}

extension $ReviewItemCopyWith on ReviewItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReviewItem.copyWith(...)` or `instanceOfReviewItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewItemCWProxy get copyWith => _$ReviewItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewItem _$ReviewItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReviewItem', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['type', 'status', 'required']);
  final val = ReviewItem(
    type: $checkedConvert('type', (v) => $enumDecode(_$ItemTypeEnumMap, v)),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$ItemStatusEnumMap, v),
    ),
    required_: $checkedConvert('required', (v) => v as bool),
    rejectionReason: $checkedConvert('rejectionReason', (v) => v as String?),
    expiresAt: $checkedConvert(
      'expiresAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    decidedAt: $checkedConvert(
      'decidedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    documents: $checkedConvert(
      'documents',
      (v) => (v as List<dynamic>?)
          ?.map((e) => ReviewDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    fields: $checkedConvert(
      'fields',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)),
    ),
  );
  return val;
}, fieldKeyMap: const {'required_': 'required'});

Map<String, dynamic> _$ReviewItemToJson(ReviewItem instance) =>
    <String, dynamic>{
      'type': _$ItemTypeEnumMap[instance.type]!,
      'status': _$ItemStatusEnumMap[instance.status]!,
      'required': instance.required_,
      'rejectionReason': ?instance.rejectionReason,
      'expiresAt': ?instance.expiresAt?.toIso8601String(),
      'decidedAt': ?instance.decidedAt?.toIso8601String(),
      'documents': ?instance.documents?.map((e) => e.toJson()).toList(),
      'fields': ?instance.fields,
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
