// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadRequestCWProxy {
  UploadRequest purpose(UploadPurpose purpose);

  UploadRequest contentType(UploadRequestContentTypeEnum contentType);

  UploadRequest sizeBytes(int sizeBytes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UploadRequest call({
    UploadPurpose purpose,
    UploadRequestContentTypeEnum contentType,
    int sizeBytes,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUploadRequest.copyWith(...)` or call `instanceOfUploadRequest.copyWith.fieldName(value)` for a single field.
class _$UploadRequestCWProxyImpl implements _$UploadRequestCWProxy {
  const _$UploadRequestCWProxyImpl(this._value);

  final UploadRequest _value;

  @override
  UploadRequest purpose(UploadPurpose purpose) => call(purpose: purpose);

  @override
  UploadRequest contentType(UploadRequestContentTypeEnum contentType) =>
      call(contentType: contentType);

  @override
  UploadRequest sizeBytes(int sizeBytes) => call(sizeBytes: sizeBytes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UploadRequest call({
    Object? purpose = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
    Object? sizeBytes = const $CopyWithPlaceholder(),
  }) {
    return UploadRequest(
      purpose: purpose == const $CopyWithPlaceholder() || purpose == null
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as UploadPurpose,
      contentType:
          contentType == const $CopyWithPlaceholder() || contentType == null
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as UploadRequestContentTypeEnum,
      sizeBytes: sizeBytes == const $CopyWithPlaceholder() || sizeBytes == null
          ? _value.sizeBytes
          // ignore: cast_nullable_to_non_nullable
          : sizeBytes as int,
    );
  }
}

extension $UploadRequestCopyWith on UploadRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUploadRequest.copyWith(...)` or `instanceOfUploadRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadRequestCWProxy get copyWith => _$UploadRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadRequest _$UploadRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UploadRequest', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['purpose', 'contentType', 'sizeBytes'],
      );
      final val = UploadRequest(
        purpose: $checkedConvert(
          'purpose',
          (v) => $enumDecode(_$UploadPurposeEnumMap, v),
        ),
        contentType: $checkedConvert(
          'contentType',
          (v) => $enumDecode(_$UploadRequestContentTypeEnumEnumMap, v),
        ),
        sizeBytes: $checkedConvert('sizeBytes', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$UploadRequestToJson(
  UploadRequest instance,
) => <String, dynamic>{
  'purpose': _$UploadPurposeEnumMap[instance.purpose]!,
  'contentType': _$UploadRequestContentTypeEnumEnumMap[instance.contentType]!,
  'sizeBytes': instance.sizeBytes,
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

const _$UploadRequestContentTypeEnumEnumMap = {
  UploadRequestContentTypeEnum.imageSlashJpeg: 'image/jpeg',
  UploadRequestContentTypeEnum.imageSlashPng: 'image/png',
  UploadRequestContentTypeEnum.applicationSlashPdf: 'application/pdf',
};
