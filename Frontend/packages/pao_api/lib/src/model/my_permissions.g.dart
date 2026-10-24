// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_permissions.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MyPermissionsCWProxy {
  MyPermissions roles(List<Role> roles);

  MyPermissions permissions(List<String> permissions);

  MyPermissions screens(List<String> screens);

  MyPermissions providerGate(bool? providerGate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPermissions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPermissions(...).copyWith(id: 12, name: "My name")
  /// ```
  MyPermissions call({
    List<Role> roles,
    List<String> permissions,
    List<String> screens,
    bool? providerGate,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMyPermissions.copyWith(...)` or call `instanceOfMyPermissions.copyWith.fieldName(value)` for a single field.
class _$MyPermissionsCWProxyImpl implements _$MyPermissionsCWProxy {
  const _$MyPermissionsCWProxyImpl(this._value);

  final MyPermissions _value;

  @override
  MyPermissions roles(List<Role> roles) => call(roles: roles);

  @override
  MyPermissions permissions(List<String> permissions) =>
      call(permissions: permissions);

  @override
  MyPermissions screens(List<String> screens) => call(screens: screens);

  @override
  MyPermissions providerGate(bool? providerGate) =>
      call(providerGate: providerGate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPermissions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPermissions(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MyPermissions call({
    Object? roles = const $CopyWithPlaceholder(),
    Object? permissions = const $CopyWithPlaceholder(),
    Object? screens = const $CopyWithPlaceholder(),
    Object? providerGate = const $CopyWithPlaceholder(),
  }) {
    return MyPermissions(
      roles: roles == const $CopyWithPlaceholder() || roles == null
          ? _value.roles
          // ignore: cast_nullable_to_non_nullable
          : roles as List<Role>,
      permissions:
          permissions == const $CopyWithPlaceholder() || permissions == null
          ? _value.permissions
          // ignore: cast_nullable_to_non_nullable
          : permissions as List<String>,
      screens: screens == const $CopyWithPlaceholder() || screens == null
          ? _value.screens
          // ignore: cast_nullable_to_non_nullable
          : screens as List<String>,
      providerGate: providerGate == const $CopyWithPlaceholder()
          ? _value.providerGate
          // ignore: cast_nullable_to_non_nullable
          : providerGate as bool?,
    );
  }
}

extension $MyPermissionsCopyWith on MyPermissions {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMyPermissions.copyWith(...)` or `instanceOfMyPermissions.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MyPermissionsCWProxy get copyWith => _$MyPermissionsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyPermissions _$MyPermissionsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MyPermissions', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['roles', 'permissions', 'screens']);
      final val = MyPermissions(
        roles: $checkedConvert(
          'roles',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$RoleEnumMap, e))
              .toList(),
        ),
        permissions: $checkedConvert(
          'permissions',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        screens: $checkedConvert(
          'screens',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        providerGate: $checkedConvert('providerGate', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$MyPermissionsToJson(MyPermissions instance) =>
    <String, dynamic>{
      'roles': instance.roles.map((e) => _$RoleEnumMap[e]!).toList(),
      'permissions': instance.permissions,
      'screens': instance.screens,
      'providerGate': ?instance.providerGate,
    };

const _$RoleEnumMap = {
  Role.customer: 'customer',
  Role.provider: 'provider',
  Role.verifier: 'verifier',
  Role.catalogManager: 'catalog_manager',
  Role.supportAgent: 'support_agent',
  Role.superAdmin: 'super_admin',
};
