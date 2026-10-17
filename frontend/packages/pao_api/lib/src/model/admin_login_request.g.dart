// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_login_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminLoginRequestCWProxy {
  AdminLoginRequest email(String email);

  AdminLoginRequest password(String password);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLoginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLoginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminLoginRequest call({String email, String password});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminLoginRequest.copyWith(...)` or call `instanceOfAdminLoginRequest.copyWith.fieldName(value)` for a single field.
class _$AdminLoginRequestCWProxyImpl implements _$AdminLoginRequestCWProxy {
  const _$AdminLoginRequestCWProxyImpl(this._value);

  final AdminLoginRequest _value;

  @override
  AdminLoginRequest email(String email) => call(email: email);

  @override
  AdminLoginRequest password(String password) => call(password: password);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLoginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLoginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminLoginRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
  }) {
    return AdminLoginRequest(
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      password: password == const $CopyWithPlaceholder() || password == null
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
    );
  }
}

extension $AdminLoginRequestCopyWith on AdminLoginRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminLoginRequest.copyWith(...)` or `instanceOfAdminLoginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminLoginRequestCWProxy get copyWith =>
      _$AdminLoginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoginRequest _$AdminLoginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminLoginRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email', 'password']);
      final val = AdminLoginRequest(
        email: $checkedConvert('email', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdminLoginRequestToJson(AdminLoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};
