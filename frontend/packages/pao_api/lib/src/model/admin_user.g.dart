// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUserCWProxy {
  AdminUser id(String id);

  AdminUser email(String email);

  AdminUser name(String name);

  AdminUser roles(List<AdminRole> roles);

  AdminUser active(bool active);

  AdminUser totpEnrolled(bool totpEnrolled);

  AdminUser lastLoginAt(DateTime? lastLoginAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUser(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUser(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminUser call({
    String id,
    String email,
    String name,
    List<AdminRole> roles,
    bool active,
    bool totpEnrolled,
    DateTime? lastLoginAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminUser.copyWith(...)` or call `instanceOfAdminUser.copyWith.fieldName(value)` for a single field.
class _$AdminUserCWProxyImpl implements _$AdminUserCWProxy {
  const _$AdminUserCWProxyImpl(this._value);

  final AdminUser _value;

  @override
  AdminUser id(String id) => call(id: id);

  @override
  AdminUser email(String email) => call(email: email);

  @override
  AdminUser name(String name) => call(name: name);

  @override
  AdminUser roles(List<AdminRole> roles) => call(roles: roles);

  @override
  AdminUser active(bool active) => call(active: active);

  @override
  AdminUser totpEnrolled(bool totpEnrolled) => call(totpEnrolled: totpEnrolled);

  @override
  AdminUser lastLoginAt(DateTime? lastLoginAt) =>
      call(lastLoginAt: lastLoginAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminUser(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminUser(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminUser call({
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? roles = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? totpEnrolled = const $CopyWithPlaceholder(),
    Object? lastLoginAt = const $CopyWithPlaceholder(),
  }) {
    return AdminUser(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
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
      active: active == const $CopyWithPlaceholder() || active == null
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      totpEnrolled:
          totpEnrolled == const $CopyWithPlaceholder() || totpEnrolled == null
          ? _value.totpEnrolled
          // ignore: cast_nullable_to_non_nullable
          : totpEnrolled as bool,
      lastLoginAt: lastLoginAt == const $CopyWithPlaceholder()
          ? _value.lastLoginAt
          // ignore: cast_nullable_to_non_nullable
          : lastLoginAt as DateTime?,
    );
  }
}

extension $AdminUserCopyWith on AdminUser {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminUser.copyWith(...)` or `instanceOfAdminUser.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUserCWProxy get copyWith => _$AdminUserCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminUser', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'email',
          'name',
          'roles',
          'active',
          'totpEnrolled',
        ],
      );
      final val = AdminUser(
        id: $checkedConvert('id', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        roles: $checkedConvert(
          'roles',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$AdminRoleEnumMap, e))
              .toList(),
        ),
        active: $checkedConvert('active', (v) => v as bool),
        totpEnrolled: $checkedConvert('totpEnrolled', (v) => v as bool),
        lastLoginAt: $checkedConvert(
          'lastLoginAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminUserToJson(AdminUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'roles': instance.roles.map((e) => _$AdminRoleEnumMap[e]!).toList(),
  'active': instance.active,
  'totpEnrolled': instance.totpEnrolled,
  'lastLoginAt': ?instance.lastLoginAt?.toIso8601String(),
};

const _$AdminRoleEnumMap = {
  AdminRole.verifier: 'verifier',
  AdminRole.catalogManager: 'catalog_manager',
  AdminRole.supportAgent: 'support_agent',
  AdminRole.superAdmin: 'super_admin',
};
