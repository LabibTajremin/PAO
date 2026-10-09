// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_definition.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoleDefinitionCWProxy {
  RoleDefinition role(Role role);

  RoleDefinition permissions(List<String> permissions);

  RoleDefinition screens(List<String> screens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoleDefinition(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoleDefinition(...).copyWith(id: 12, name: "My name")
  /// ```
  RoleDefinition call({
    Role role,
    List<String> permissions,
    List<String> screens,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRoleDefinition.copyWith(...)` or call `instanceOfRoleDefinition.copyWith.fieldName(value)` for a single field.
class _$RoleDefinitionCWProxyImpl implements _$RoleDefinitionCWProxy {
  const _$RoleDefinitionCWProxyImpl(this._value);

  final RoleDefinition _value;

  @override
  RoleDefinition role(Role role) => call(role: role);

  @override
  RoleDefinition permissions(List<String> permissions) =>
      call(permissions: permissions);

  @override
  RoleDefinition screens(List<String> screens) => call(screens: screens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoleDefinition(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoleDefinition(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RoleDefinition call({
    Object? role = const $CopyWithPlaceholder(),
    Object? permissions = const $CopyWithPlaceholder(),
    Object? screens = const $CopyWithPlaceholder(),
  }) {
    return RoleDefinition(
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as Role,
      permissions:
          permissions == const $CopyWithPlaceholder() || permissions == null
          ? _value.permissions
          // ignore: cast_nullable_to_non_nullable
          : permissions as List<String>,
      screens: screens == const $CopyWithPlaceholder() || screens == null
          ? _value.screens
          // ignore: cast_nullable_to_non_nullable
          : screens as List<String>,
    );
  }
}

extension $RoleDefinitionCopyWith on RoleDefinition {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRoleDefinition.copyWith(...)` or `instanceOfRoleDefinition.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RoleDefinitionCWProxy get copyWith => _$RoleDefinitionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleDefinition _$RoleDefinitionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RoleDefinition', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['role', 'permissions', 'screens']);
      final val = RoleDefinition(
        role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
        permissions: $checkedConvert(
          'permissions',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        screens: $checkedConvert(
          'screens',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RoleDefinitionToJson(RoleDefinition instance) =>
    <String, dynamic>{
      'role': _$RoleEnumMap[instance.role]!,
      'permissions': instance.permissions,
      'screens': instance.screens,
    };

const _$RoleEnumMap = {
  Role.customer: 'customer',
  Role.provider: 'provider',
  Role.verifier: 'verifier',
  Role.catalogManager: 'catalog_manager',
  Role.supportAgent: 'support_agent',
  Role.superAdmin: 'super_admin',
};
