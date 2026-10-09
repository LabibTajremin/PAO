// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_enrolment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TotpEnrolmentCWProxy {
  TotpEnrolment secret(String secret);

  TotpEnrolment otpauthUrl(String otpauthUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TotpEnrolment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TotpEnrolment(...).copyWith(id: 12, name: "My name")
  /// ```
  TotpEnrolment call({String secret, String otpauthUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTotpEnrolment.copyWith(...)` or call `instanceOfTotpEnrolment.copyWith.fieldName(value)` for a single field.
class _$TotpEnrolmentCWProxyImpl implements _$TotpEnrolmentCWProxy {
  const _$TotpEnrolmentCWProxyImpl(this._value);

  final TotpEnrolment _value;

  @override
  TotpEnrolment secret(String secret) => call(secret: secret);

  @override
  TotpEnrolment otpauthUrl(String otpauthUrl) => call(otpauthUrl: otpauthUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TotpEnrolment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TotpEnrolment(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TotpEnrolment call({
    Object? secret = const $CopyWithPlaceholder(),
    Object? otpauthUrl = const $CopyWithPlaceholder(),
  }) {
    return TotpEnrolment(
      secret: secret == const $CopyWithPlaceholder() || secret == null
          ? _value.secret
          // ignore: cast_nullable_to_non_nullable
          : secret as String,
      otpauthUrl:
          otpauthUrl == const $CopyWithPlaceholder() || otpauthUrl == null
          ? _value.otpauthUrl
          // ignore: cast_nullable_to_non_nullable
          : otpauthUrl as String,
    );
  }
}

extension $TotpEnrolmentCopyWith on TotpEnrolment {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTotpEnrolment.copyWith(...)` or `instanceOfTotpEnrolment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TotpEnrolmentCWProxy get copyWith => _$TotpEnrolmentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotpEnrolment _$TotpEnrolmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TotpEnrolment', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['secret', 'otpauthUrl']);
      final val = TotpEnrolment(
        secret: $checkedConvert('secret', (v) => v as String),
        otpauthUrl: $checkedConvert('otpauthUrl', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TotpEnrolmentToJson(TotpEnrolment instance) =>
    <String, dynamic>{
      'secret': instance.secret,
      'otpauthUrl': instance.otpauthUrl,
    };
