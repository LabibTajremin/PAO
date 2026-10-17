// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoleListCWProxy {
  RoleList items(List<RoleDefinition> items);

  RoleList allPermissions(List<String> allPermissions);

  RoleList allScreens(List<String> allScreens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoleList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoleList(...).copyWith(id: 12, name: "My name")
  /// ```
  RoleList call({
    List<RoleDefinition> items,
    List<String> allPermissions,
    List<String> allScreens,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRoleList.copyWith(...)` or call `instanceOfRoleList.copyWith.fieldName(value)` for a single field.
class _$RoleListCWProxyImpl implements _$RoleListCWProxy {
  const _$RoleListCWProxyImpl(this._value);

  final RoleList _value;

  @override
  RoleList items(List<RoleDefinition> items) => call(items: items);

  @override
  RoleList allPermissions(List<String> allPermissions) =>
      call(allPermissions: allPermissions);

  @override
  RoleList allScreens(List<String> allScreens) => call(allScreens: allScreens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoleList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoleList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RoleList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? allPermissions = const $CopyWithPlaceholder(),
    Object? allScreens = const $CopyWithPlaceholder(),
  }) {
    return RoleList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<RoleDefinition>,
      allPermissions:
          allPermissions == const $CopyWithPlaceholder() ||
              allPermissions == null
          ? _value.allPermissions
          // ignore: cast_nullable_to_non_nullable
          : allPermissions as List<String>,
      allScreens:
          allScreens == const $CopyWithPlaceholder() || allScreens == null
          ? _value.allScreens
          // ignore: cast_nullable_to_non_nullable
          : allScreens as List<String>,
    );
  }
}

extension $RoleListCopyWith on RoleList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRoleList.copyWith(...)` or `instanceOfRoleList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RoleListCWProxy get copyWith => _$RoleListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleList _$RoleListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RoleList', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['items', 'allPermissions', 'allScreens'],
      );
      final val = RoleList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => RoleDefinition.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        allPermissions: $checkedConvert(
          'allPermissions',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        allScreens: $checkedConvert(
          'allScreens',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RoleListToJson(RoleList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'allPermissions': instance.allPermissions,
  'allScreens': instance.allScreens,
};
