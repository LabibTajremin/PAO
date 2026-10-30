// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OtpRequestCWProxy {
  OtpRequest phone(String phone);

  OtpRequest purpose(OtpPurpose? purpose);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OtpRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OtpRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  OtpRequest call({String phone, OtpPurpose? purpose});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOtpRequest.copyWith(...)` or call `instanceOfOtpRequest.copyWith.fieldName(value)` for a single field.
class _$OtpRequestCWProxyImpl implements _$OtpRequestCWProxy {
  const _$OtpRequestCWProxyImpl(this._value);

  final OtpRequest _value;

  @override
  OtpRequest phone(String phone) => call(phone: phone);

  @override
  OtpRequest purpose(OtpPurpose? purpose) => call(purpose: purpose);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OtpRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OtpRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OtpRequest call({
    Object? phone = const $CopyWithPlaceholder(),
    Object? purpose = const $CopyWithPlaceholder(),
  }) {
    return OtpRequest(
      phone: phone == const $CopyWithPlaceholder() || phone == null
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      purpose: purpose == const $CopyWithPlaceholder()
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as OtpPurpose?,
    );
  }
}

extension $OtpRequestCopyWith on OtpRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOtpRequest.copyWith(...)` or `instanceOfOtpRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OtpRequestCWProxy get copyWith => _$OtpRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpRequest _$OtpRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OtpRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone']);
      final val = OtpRequest(
        phone: $checkedConvert('phone', (v) => v as String),
        purpose: $checkedConvert(
          'purpose',
          (v) => $enumDecodeNullable(_$OtpPurposeEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OtpRequestToJson(OtpRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'purpose': ?_$OtpPurposeEnumMap[instance.purpose],
    };

const _$OtpPurposeEnumMap = {
  OtpPurpose.login: 'login',
  OtpPurpose.deleteAccount: 'delete_account',
};
