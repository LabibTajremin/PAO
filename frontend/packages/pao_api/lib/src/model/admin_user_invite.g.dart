// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_invite.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUserInviteCWProxy {
  AdminUserInvite email(String email);

  AdminUserInvite name(String name);

  AdminUserInvite roles(List<AdminRole> roles);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserInvite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserInvite(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminUserInvite call({String email, String name, List<AdminRole> roles});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminUserInvite.copyWith(...)` or call `instanceOfAdminUserInvite.copyWith.fieldName(value)` for a single field.
class _$AdminUserInviteCWProxyImpl implements _$AdminUserInviteCWProxy {
  const _$AdminUserInviteCWProxyImpl(this._value);

  final AdminUserInvite _value;

  @override
  AdminUserInvite email(String email) => call(email: email);

  @override
  AdminUserInvite name(String name) => call(name: name);

  @override
  AdminUserInvite roles(List<AdminRole> roles) => call(roles: roles);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserInvite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserInvite(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminUserInvite call({
    Object? email = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? roles = const $CopyWithPlaceholder(),
  }) {
    return AdminUserInvite(
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      roles: roles == const $CopyWithPlaceholder() || roles == null
          ? _value.roles
          // ignore: cast_nullable_to_non_nullable
          : roles as List<AdminRole>,
    );
  }
}

extension $AdminUserInviteCopyWith on AdminUserInvite {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminUserInvite.copyWith(...)` or `instanceOfAdminUserInvite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUserInviteCWProxy get copyWith => _$AdminUserInviteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserInvite _$AdminUserInviteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminUserInvite', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email', 'name', 'roles']);
      final val = AdminUserInvite(
        email: $checkedConvert('email', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        roles: $checkedConvert(
          'roles',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$AdminRoleEnumMap, e))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminUserInviteToJson(AdminUserInvite instance) =>
    <String, dynamic>{
      'email': instance.email,
      'name': instance.name,
      'roles': instance.roles.map((e) => _$AdminRoleEnumMap[e]!).toList(),
    };

const _$AdminRoleEnumMap = {
  AdminRole.verifier: 'verifier',
  AdminRole.catalogManager: 'catalog_manager',
  AdminRole.supportAgent: 'support_agent',
  AdminRole.superAdmin: 'super_admin',
};
