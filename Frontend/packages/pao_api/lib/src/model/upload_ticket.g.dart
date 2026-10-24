// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_ticket.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadTicketCWProxy {
  UploadTicket mediaId(String mediaId);

  UploadTicket uploadUrl(String uploadUrl);

  UploadTicket headers(Map<String, String> headers);

  UploadTicket expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadTicket(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadTicket(...).copyWith(id: 12, name: "My name")
  /// ```
  UploadTicket call({
    String mediaId,
    String uploadUrl,
    Map<String, String> headers,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUploadTicket.copyWith(...)` or call `instanceOfUploadTicket.copyWith.fieldName(value)` for a single field.
class _$UploadTicketCWProxyImpl implements _$UploadTicketCWProxy {
  const _$UploadTicketCWProxyImpl(this._value);

  final UploadTicket _value;

  @override
  UploadTicket mediaId(String mediaId) => call(mediaId: mediaId);

  @override
  UploadTicket uploadUrl(String uploadUrl) => call(uploadUrl: uploadUrl);

  @override
  UploadTicket headers(Map<String, String> headers) => call(headers: headers);

  @override
  UploadTicket expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadTicket(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadTicket(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UploadTicket call({
    Object? mediaId = const $CopyWithPlaceholder(),
    Object? uploadUrl = const $CopyWithPlaceholder(),
    Object? headers = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return UploadTicket(
      mediaId: mediaId == const $CopyWithPlaceholder() || mediaId == null
          ? _value.mediaId
          // ignore: cast_nullable_to_non_nullable
          : mediaId as String,
      uploadUrl: uploadUrl == const $CopyWithPlaceholder() || uploadUrl == null
          ? _value.uploadUrl
          // ignore: cast_nullable_to_non_nullable
          : uploadUrl as String,
      headers: headers == const $CopyWithPlaceholder() || headers == null
          ? _value.headers
          // ignore: cast_nullable_to_non_nullable
          : headers as Map<String, String>,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $UploadTicketCopyWith on UploadTicket {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUploadTicket.copyWith(...)` or `instanceOfUploadTicket.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadTicketCWProxy get copyWith => _$UploadTicketCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadTicket _$UploadTicketFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UploadTicket', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['mediaId', 'uploadUrl', 'headers', 'expiresAt'],
      );
      final val = UploadTicket(
        mediaId: $checkedConvert('mediaId', (v) => v as String),
        uploadUrl: $checkedConvert('uploadUrl', (v) => v as String),
        headers: $checkedConvert(
          'headers',
          (v) => Map<String, String>.from(v as Map),
        ),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UploadTicketToJson(UploadTicket instance) =>
    <String, dynamic>{
      'mediaId': instance.mediaId,
      'uploadUrl': instance.uploadUrl,
      'headers': instance.headers,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
