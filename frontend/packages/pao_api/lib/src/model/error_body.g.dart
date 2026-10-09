// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_body.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ErrorBodyCWProxy {
  ErrorBody code(ErrorCode code);

  ErrorBody message(String message);

  ErrorBody details(Map<String, Object>? details);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorBody(...).copyWith(id: 12, name: "My name")
  /// ```
  ErrorBody call({
    ErrorCode code,
    String message,
    Map<String, Object>? details,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfErrorBody.copyWith(...)` or call `instanceOfErrorBody.copyWith.fieldName(value)` for a single field.
class _$ErrorBodyCWProxyImpl implements _$ErrorBodyCWProxy {
  const _$ErrorBodyCWProxyImpl(this._value);

  final ErrorBody _value;

  @override
  ErrorBody code(ErrorCode code) => call(code: code);

  @override
  ErrorBody message(String message) => call(message: message);

  @override
  ErrorBody details(Map<String, Object>? details) => call(details: details);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorBody(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ErrorBody call({
    Object? code = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? details = const $CopyWithPlaceholder(),
  }) {
    return ErrorBody(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as ErrorCode,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      details: details == const $CopyWithPlaceholder()
          ? _value.details
          // ignore: cast_nullable_to_non_nullable
          : details as Map<String, Object>?,
    );
  }
}

extension $ErrorBodyCopyWith on ErrorBody {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfErrorBody.copyWith(...)` or `instanceOfErrorBody.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ErrorBodyCWProxy get copyWith => _$ErrorBodyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorBody _$ErrorBodyFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ErrorBody', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code', 'message']);
  final val = ErrorBody(
    code: $checkedConvert('code', (v) => $enumDecode(_$ErrorCodeEnumMap, v)),
    message: $checkedConvert('message', (v) => v as String),
    details: $checkedConvert(
      'details',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as Object)),
    ),
  );
  return val;
});

Map<String, dynamic> _$ErrorBodyToJson(ErrorBody instance) => <String, dynamic>{
  'code': _$ErrorCodeEnumMap[instance.code]!,
  'message': instance.message,
  'details': ?instance.details,
};

const _$ErrorCodeEnumMap = {
  ErrorCode.VALIDATION_FAILED: 'VALIDATION_FAILED',
  ErrorCode.UNAUTHENTICATED: 'UNAUTHENTICATED',
  ErrorCode.TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  ErrorCode.FORBIDDEN: 'FORBIDDEN',
  ErrorCode.NOT_FOUND: 'NOT_FOUND',
  ErrorCode.CONFLICT: 'CONFLICT',
  ErrorCode.RATE_LIMITED: 'RATE_LIMITED',
  ErrorCode.INTERNAL: 'INTERNAL',
  ErrorCode.NOT_IMPLEMENTED: 'NOT_IMPLEMENTED',
  ErrorCode.OTP_INVALID: 'OTP_INVALID',
  ErrorCode.OTP_EXPIRED: 'OTP_EXPIRED',
  ErrorCode.OTP_LOCKED: 'OTP_LOCKED',
  ErrorCode.ACCOUNT_BANNED: 'ACCOUNT_BANNED',
  ErrorCode.ACCOUNT_SUSPENDED: 'ACCOUNT_SUSPENDED',
  ErrorCode.INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  ErrorCode.ACCOUNT_LOCKED: 'ACCOUNT_LOCKED',
  ErrorCode.TOTP_INVALID: 'TOTP_INVALID',
  ErrorCode.MFA_CHALLENGE_EXPIRED: 'MFA_CHALLENGE_EXPIRED',
  ErrorCode.REFRESH_TOKEN_INVALID: 'REFRESH_TOKEN_INVALID',
  ErrorCode.IDEMPOTENCY_KEY_REQUIRED: 'IDEMPOTENCY_KEY_REQUIRED',
  ErrorCode.IDEMPOTENCY_KEY_REUSED: 'IDEMPOTENCY_KEY_REUSED',
  ErrorCode.ADDRESS_LIMIT_REACHED: 'ADDRESS_LIMIT_REACHED',
  ErrorCode.OUTSIDE_SERVICE_AREA: 'OUTSIDE_SERVICE_AREA',
  ErrorCode.SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
  ErrorCode.PROVIDER_UNAVAILABLE: 'PROVIDER_UNAVAILABLE',
  ErrorCode.DUPLICATE_BOOKING_REQUEST: 'DUPLICATE_BOOKING_REQUEST',
  ErrorCode.BOOKING_INVALID_TRANSITION: 'BOOKING_INVALID_TRANSITION',
  ErrorCode.BOOKING_ALREADY_RESPONDED: 'BOOKING_ALREADY_RESPONDED',
  ErrorCode.ACTIVE_JOB_EXISTS: 'ACTIVE_JOB_EXISTS',
  ErrorCode.START_CODE_INVALID: 'START_CODE_INVALID',
  ErrorCode.START_CODE_LOCKED: 'START_CODE_LOCKED',
  ErrorCode.CANCELLATION_NOT_ALLOWED: 'CANCELLATION_NOT_ALLOWED',
  ErrorCode.EXTRA_ITEM_INVALID: 'EXTRA_ITEM_INVALID',
  ErrorCode.EXTRAS_PENDING: 'EXTRAS_PENDING',
  ErrorCode.CASH_CONFIRMATION_REQUIRED: 'CASH_CONFIRMATION_REQUIRED',
  ErrorCode.REVIEW_NOT_ALLOWED: 'REVIEW_NOT_ALLOWED',
  ErrorCode.REVIEW_ALREADY_SUBMITTED: 'REVIEW_ALREADY_SUBMITTED',
  ErrorCode.UPLOAD_INVALID: 'UPLOAD_INVALID',
  ErrorCode.UPLOAD_NOT_FOUND: 'UPLOAD_NOT_FOUND',
  ErrorCode.ENROLMENT_INCOMPLETE: 'ENROLMENT_INCOMPLETE',
  ErrorCode.NOT_VERIFIED: 'NOT_VERIFIED',
  ErrorCode.AGE_REQUIREMENT: 'AGE_REQUIREMENT',
  ErrorCode.lEVEL2COOLINGOFF: 'LEVEL2_COOLING_OFF',
  ErrorCode.COMPLAINT_INVALID_TRANSITION: 'COMPLAINT_INVALID_TRANSITION',
  ErrorCode.SETTING_INVALID: 'SETTING_INVALID',
  ErrorCode.ROLE_INVALID: 'ROLE_INVALID',
};
