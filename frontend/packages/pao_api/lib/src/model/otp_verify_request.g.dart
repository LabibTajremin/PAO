// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_verify_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OtpVerifyRequestCWProxy {
  OtpVerifyRequest phone(String phone);

  OtpVerifyRequest code(String code);

  OtpVerifyRequest app(AppKind app);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OtpVerifyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OtpVerifyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  OtpVerifyRequest call({String phone, String code, AppKind app});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOtpVerifyRequest.copyWith(...)` or call `instanceOfOtpVerifyRequest.copyWith.fieldName(value)` for a single field.
class _$OtpVerifyRequestCWProxyImpl implements _$OtpVerifyRequestCWProxy {
  const _$OtpVerifyRequestCWProxyImpl(this._value);

  final OtpVerifyRequest _value;

  @override
  OtpVerifyRequest phone(String phone) => call(phone: phone);

  @override
  OtpVerifyRequest code(String code) => call(code: code);

  @override
  OtpVerifyRequest app(AppKind app) => call(app: app);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OtpVerifyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OtpVerifyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OtpVerifyRequest call({
    Object? phone = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? app = const $CopyWithPlaceholder(),
  }) {
    return OtpVerifyRequest(
      phone: phone == const $CopyWithPlaceholder() || phone == null
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      app: app == const $CopyWithPlaceholder() || app == null
          ? _value.app
          // ignore: cast_nullable_to_non_nullable
          : app as AppKind,
    );
  }
}

extension $OtpVerifyRequestCopyWith on OtpVerifyRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOtpVerifyRequest.copyWith(...)` or `instanceOfOtpVerifyRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OtpVerifyRequestCWProxy get copyWith => _$OtpVerifyRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpVerifyRequest _$OtpVerifyRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OtpVerifyRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone', 'code', 'app']);
      final val = OtpVerifyRequest(
        phone: $checkedConvert('phone', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
        app: $checkedConvert('app', (v) => $enumDecode(_$AppKindEnumMap, v)),
      );
      return val;
    });

Map<String, dynamic> _$OtpVerifyRequestToJson(OtpVerifyRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'code': instance.code,
      'app': _$AppKindEnumMap[instance.app]!,
    };

const _$AppKindEnumMap = {
  AppKind.customer: 'customer',
  AppKind.partner: 'partner',
};
