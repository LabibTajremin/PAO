// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_invited.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUserInvitedCWProxy {
  AdminUserInvited user(AdminUser user);

  AdminUserInvited temporaryPassword(String temporaryPassword);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserInvited(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserInvited(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminUserInvited call({AdminUser user, String temporaryPassword});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminUserInvited.copyWith(...)` or call `instanceOfAdminUserInvited.copyWith.fieldName(value)` for a single field.
class _$AdminUserInvitedCWProxyImpl implements _$AdminUserInvitedCWProxy {
  const _$AdminUserInvitedCWProxyImpl(this._value);

  final AdminUserInvited _value;

  @override
  AdminUserInvited user(AdminUser user) => call(user: user);

  @override
  AdminUserInvited temporaryPassword(String temporaryPassword) =>
      call(temporaryPassword: temporaryPassword);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserInvited(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserInvited(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminUserInvited call({
    Object? user = const $CopyWithPlaceholder(),
    Object? temporaryPassword = const $CopyWithPlaceholder(),
  }) {
    return AdminUserInvited(
      user: user == const $CopyWithPlaceholder() || user == null
          ? _value.user
          // ignore: cast_nullable_to_non_nullable
          : user as AdminUser,
      temporaryPassword:
          temporaryPassword == const $CopyWithPlaceholder() ||
              temporaryPassword == null
          ? _value.temporaryPassword
          // ignore: cast_nullable_to_non_nullable
          : temporaryPassword as String,
    );
  }
}

extension $AdminUserInvitedCopyWith on AdminUserInvited {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminUserInvited.copyWith(...)` or `instanceOfAdminUserInvited.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUserInvitedCWProxy get copyWith => _$AdminUserInvitedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserInvited _$AdminUserInvitedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminUserInvited', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['user', 'temporaryPassword']);
      final val = AdminUserInvited(
        user: $checkedConvert(
          'user',
          (v) => AdminUser.fromJson(v as Map<String, dynamic>),
        ),
        temporaryPassword: $checkedConvert(
          'temporaryPassword',
          (v) => v as String,
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminUserInvitedToJson(AdminUserInvited instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'temporaryPassword': instance.temporaryPassword,
    };
