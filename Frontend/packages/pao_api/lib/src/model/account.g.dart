// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountCWProxy {
  Account id(String id);

  Account phone(String? phone);

  Account email(String? email);

  Account roles(List<Role> roles);

  Account status(AccountStatus status);

  Account createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Account(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Account(...).copyWith(id: 12, name: "My name")
  /// ```
  Account call({
    String id,
    String? phone,
    String? email,
    List<Role> roles,
    AccountStatus status,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAccount.copyWith(...)` or call `instanceOfAccount.copyWith.fieldName(value)` for a single field.
class _$AccountCWProxyImpl implements _$AccountCWProxy {
  const _$AccountCWProxyImpl(this._value);

  final Account _value;

  @override
  Account id(String id) => call(id: id);

  @override
  Account phone(String? phone) => call(phone: phone);

  @override
  Account email(String? email) => call(email: email);

  @override
  Account roles(List<Role> roles) => call(roles: roles);

  @override
  Account status(AccountStatus status) => call(status: status);

  @override
  Account createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Account(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Account(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Account call({
    Object? id = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? roles = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Account(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      roles: roles == const $CopyWithPlaceholder() || roles == null
          ? _value.roles
          // ignore: cast_nullable_to_non_nullable
          : roles as List<Role>,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AccountStatus,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $AccountCopyWith on Account {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAccount.copyWith(...)` or `instanceOfAccount.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountCWProxy get copyWith => _$AccountCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Account', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'roles', 'status', 'createdAt']);
  final val = Account(
    id: $checkedConvert('id', (v) => v as String),
    phone: $checkedConvert('phone', (v) => v as String?),
    email: $checkedConvert('email', (v) => v as String?),
    roles: $checkedConvert(
      'roles',
      (v) => (v as List<dynamic>)
          .map((e) => $enumDecode(_$RoleEnumMap, e))
          .toList(),
    ),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$AccountStatusEnumMap, v),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': instance.id,
  'phone': ?instance.phone,
  'email': ?instance.email,
  'roles': instance.roles.map((e) => _$RoleEnumMap[e]!).toList(),
  'status': _$AccountStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$RoleEnumMap = {
  Role.customer: 'customer',
  Role.provider: 'provider',
  Role.verifier: 'verifier',
  Role.catalogManager: 'catalog_manager',
  Role.supportAgent: 'support_agent',
  Role.superAdmin: 'super_admin',
};

const _$AccountStatusEnumMap = {
  AccountStatus.pending: 'pending',
  AccountStatus.active: 'active',
  AccountStatus.suspended: 'suspended',
  AccountStatus.banned: 'banned',
};
