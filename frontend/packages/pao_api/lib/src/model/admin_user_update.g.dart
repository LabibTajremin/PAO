// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUserUpdateCWProxy {
  AdminUserUpdate roles(List<AdminRole>? roles);

  AdminUserUpdate active(bool? active);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminUserUpdate call({List<AdminRole>? roles, bool? active});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminUserUpdate.copyWith(...)` or call `instanceOfAdminUserUpdate.copyWith.fieldName(value)` for a single field.
class _$AdminUserUpdateCWProxyImpl implements _$AdminUserUpdateCWProxy {
  const _$AdminUserUpdateCWProxyImpl(this._value);

  final AdminUserUpdate _value;

  @override
  AdminUserUpdate roles(List<AdminRole>? roles) => call(roles: roles);

  @override
  AdminUserUpdate active(bool? active) => call(active: active);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUserUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUserUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminUserUpdate call({
    Object? roles = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
  }) {
    return AdminUserUpdate(
      roles: roles == const $CopyWithPlaceholder()
          ? _value.roles
          // ignore: cast_nullable_to_non_nullable
          : roles as List<AdminRole>?,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool?,
    );
  }
}

extension $AdminUserUpdateCopyWith on AdminUserUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminUserUpdate.copyWith(...)` or `instanceOfAdminUserUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUserUpdateCWProxy get copyWith => _$AdminUserUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUserUpdate _$AdminUserUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminUserUpdate', json, ($checkedConvert) {
      final val = AdminUserUpdate(
        roles: $checkedConvert(
          'roles',
          (v) => (v as List<dynamic>?)
              ?.map((e) => $enumDecode(_$AdminRoleEnumMap, e))
              .toList(),
        ),
        active: $checkedConvert('active', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$AdminUserUpdateToJson(AdminUserUpdate instance) =>
    <String, dynamic>{
      'roles': ?instance.roles?.map((e) => _$AdminRoleEnumMap[e]!).toList(),
      'active': ?instance.active,
    };

const _$AdminRoleEnumMap = {
  AdminRole.verifier: 'verifier',
  AdminRole.catalogManager: 'catalog_manager',
  AdminRole.supportAgent: 'support_agent',
  AdminRole.superAdmin: 'super_admin',
};
