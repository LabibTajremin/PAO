// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MediaObjectCWProxy {
  MediaObject id(String id);

  MediaObject purpose(UploadPurpose purpose);

  MediaObject contentType(String contentType);

  MediaObject sizeBytes(int sizeBytes);

  MediaObject status(MediaObjectStatusEnum status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MediaObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MediaObject(...).copyWith(id: 12, name: "My name")
  /// ```
  MediaObject call({
    String id,
    UploadPurpose purpose,
    String contentType,
    int sizeBytes,
    MediaObjectStatusEnum status,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMediaObject.copyWith(...)` or call `instanceOfMediaObject.copyWith.fieldName(value)` for a single field.
class _$MediaObjectCWProxyImpl implements _$MediaObjectCWProxy {
  const _$MediaObjectCWProxyImpl(this._value);

  final MediaObject _value;

  @override
  MediaObject id(String id) => call(id: id);

  @override
  MediaObject purpose(UploadPurpose purpose) => call(purpose: purpose);

  @override
  MediaObject contentType(String contentType) => call(contentType: contentType);

  @override
  MediaObject sizeBytes(int sizeBytes) => call(sizeBytes: sizeBytes);

  @override
  MediaObject status(MediaObjectStatusEnum status) => call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MediaObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MediaObject(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MediaObject call({
    Object? id = const $CopyWithPlaceholder(),
    Object? purpose = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
    Object? sizeBytes = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return MediaObject(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      purpose: purpose == const $CopyWithPlaceholder() || purpose == null
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as UploadPurpose,
      contentType:
          contentType == const $CopyWithPlaceholder() || contentType == null
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as String,
      sizeBytes: sizeBytes == const $CopyWithPlaceholder() || sizeBytes == null
          ? _value.sizeBytes
          // ignore: cast_nullable_to_non_nullable
          : sizeBytes as int,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as MediaObjectStatusEnum,
    );
  }
}

extension $MediaObjectCopyWith on MediaObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMediaObject.copyWith(...)` or `instanceOfMediaObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MediaObjectCWProxy get copyWith => _$MediaObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaObject _$MediaObjectFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MediaObject', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'purpose',
          'contentType',
          'sizeBytes',
          'status',
        ],
      );
      final val = MediaObject(
        id: $checkedConvert('id', (v) => v as String),
        purpose: $checkedConvert(
          'purpose',
          (v) => $enumDecode(_$UploadPurposeEnumMap, v),
        ),
        contentType: $checkedConvert('contentType', (v) => v as String),
        sizeBytes: $checkedConvert('sizeBytes', (v) => (v as num).toInt()),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$MediaObjectStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MediaObjectToJson(MediaObject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'purpose': _$UploadPurposeEnumMap[instance.purpose]!,
      'contentType': instance.contentType,
      'sizeBytes': instance.sizeBytes,
      'status': _$MediaObjectStatusEnumEnumMap[instance.status]!,
    };

const _$UploadPurposeEnumMap = {
  UploadPurpose.avatar: 'avatar',
  UploadPurpose.nidFront: 'nid_front',
  UploadPurpose.nidBack: 'nid_back',
  UploadPurpose.selfie: 'selfie',
  UploadPurpose.policeClearance: 'police_clearance',
  UploadPurpose.skillProof: 'skill_proof',
  UploadPurpose.addressProof: 'address_proof',
  UploadPurpose.complaintPhoto: 'complaint_photo',
  UploadPurpose.level2Photo: 'level2_photo',
};

const _$MediaObjectStatusEnumEnumMap = {
  MediaObjectStatusEnum.pending: 'pending',
  MediaObjectStatusEnum.confirmed: 'confirmed',
};
