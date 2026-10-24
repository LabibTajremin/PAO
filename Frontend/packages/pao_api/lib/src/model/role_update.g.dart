// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoleUpdateCWProxy {
  RoleUpdate permissions(List<String> permissions);

  RoleUpdate screens(List<String> screens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoleUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoleUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  RoleUpdate call({List<String> permissions, List<String> screens});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRoleUpdate.copyWith(...)` or call `instanceOfRoleUpdate.copyWith.fieldName(value)` for a single field.
class _$RoleUpdateCWProxyImpl implements _$RoleUpdateCWProxy {
  const _$RoleUpdateCWProxyImpl(this._value);

  final RoleUpdate _value;

  @override
  RoleUpdate permissions(List<String> permissions) =>
      call(permissions: permissions);

  @override
  RoleUpdate screens(List<String> screens) => call(screens: screens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoleUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoleUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RoleUpdate call({
    Object? permissions = const $CopyWithPlaceholder(),
    Object? screens = const $CopyWithPlaceholder(),
  }) {
    return RoleUpdate(
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

extension $RoleUpdateCopyWith on RoleUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRoleUpdate.copyWith(...)` or `instanceOfRoleUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RoleUpdateCWProxy get copyWith => _$RoleUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleUpdate _$RoleUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RoleUpdate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['permissions', 'screens']);
      final val = RoleUpdate(
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

Map<String, dynamic> _$RoleUpdateToJson(RoleUpdate instance) =>
    <String, dynamic>{
      'permissions': instance.permissions,
      'screens': instance.screens,
    };
