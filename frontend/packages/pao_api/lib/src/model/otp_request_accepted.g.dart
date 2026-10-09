// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_request_accepted.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OtpRequestAcceptedCWProxy {
  OtpRequestAccepted expiresInSeconds(int expiresInSeconds);

  OtpRequestAccepted resendAfterSeconds(int resendAfterSeconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OtpRequestAccepted(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OtpRequestAccepted(...).copyWith(id: 12, name: "My name")
  /// ```
  OtpRequestAccepted call({int expiresInSeconds, int resendAfterSeconds});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOtpRequestAccepted.copyWith(...)` or call `instanceOfOtpRequestAccepted.copyWith.fieldName(value)` for a single field.
class _$OtpRequestAcceptedCWProxyImpl implements _$OtpRequestAcceptedCWProxy {
  const _$OtpRequestAcceptedCWProxyImpl(this._value);

  final OtpRequestAccepted _value;

  @override
  OtpRequestAccepted expiresInSeconds(int expiresInSeconds) =>
      call(expiresInSeconds: expiresInSeconds);

  @override
  OtpRequestAccepted resendAfterSeconds(int resendAfterSeconds) =>
      call(resendAfterSeconds: resendAfterSeconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OtpRequestAccepted(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OtpRequestAccepted(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OtpRequestAccepted call({
    Object? expiresInSeconds = const $CopyWithPlaceholder(),
    Object? resendAfterSeconds = const $CopyWithPlaceholder(),
  }) {
    return OtpRequestAccepted(
      expiresInSeconds:
          expiresInSeconds == const $CopyWithPlaceholder() ||
              expiresInSeconds == null
          ? _value.expiresInSeconds
          // ignore: cast_nullable_to_non_nullable
          : expiresInSeconds as int,
      resendAfterSeconds:
          resendAfterSeconds == const $CopyWithPlaceholder() ||
              resendAfterSeconds == null
          ? _value.resendAfterSeconds
          // ignore: cast_nullable_to_non_nullable
          : resendAfterSeconds as int,
    );
  }
}

extension $OtpRequestAcceptedCopyWith on OtpRequestAccepted {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOtpRequestAccepted.copyWith(...)` or `instanceOfOtpRequestAccepted.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OtpRequestAcceptedCWProxy get copyWith =>
      _$OtpRequestAcceptedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpRequestAccepted _$OtpRequestAcceptedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OtpRequestAccepted', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['expiresInSeconds', 'resendAfterSeconds'],
      );
      final val = OtpRequestAccepted(
        expiresInSeconds: $checkedConvert(
          'expiresInSeconds',
          (v) => (v as num).toInt(),
        ),
        resendAfterSeconds: $checkedConvert(
          'resendAfterSeconds',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OtpRequestAcceptedToJson(OtpRequestAccepted instance) =>
    <String, dynamic>{
      'expiresInSeconds': instance.expiresInSeconds,
      'resendAfterSeconds': instance.resendAfterSeconds,
    };
