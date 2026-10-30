// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_password_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPasswordChangeCWProxy {
  AdminPasswordChange currentPassword(String currentPassword);

  AdminPasswordChange newPassword(String newPassword);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPasswordChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPasswordChange(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminPasswordChange call({String currentPassword, String newPassword});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminPasswordChange.copyWith(...)` or call `instanceOfAdminPasswordChange.copyWith.fieldName(value)` for a single field.
class _$AdminPasswordChangeCWProxyImpl implements _$AdminPasswordChangeCWProxy {
  const _$AdminPasswordChangeCWProxyImpl(this._value);

  final AdminPasswordChange _value;

  @override
  AdminPasswordChange currentPassword(String currentPassword) =>
      call(currentPassword: currentPassword);

  @override
  AdminPasswordChange newPassword(String newPassword) =>
      call(newPassword: newPassword);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPasswordChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPasswordChange(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminPasswordChange call({
    Object? currentPassword = const $CopyWithPlaceholder(),
    Object? newPassword = const $CopyWithPlaceholder(),
  }) {
    return AdminPasswordChange(
      currentPassword:
          currentPassword == const $CopyWithPlaceholder() ||
              currentPassword == null
          ? _value.currentPassword
          // ignore: cast_nullable_to_non_nullable
          : currentPassword as String,
      newPassword:
          newPassword == const $CopyWithPlaceholder() || newPassword == null
          ? _value.newPassword
          // ignore: cast_nullable_to_non_nullable
          : newPassword as String,
    );
  }
}

extension $AdminPasswordChangeCopyWith on AdminPasswordChange {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminPasswordChange.copyWith(...)` or `instanceOfAdminPasswordChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPasswordChangeCWProxy get copyWith =>
      _$AdminPasswordChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPasswordChange _$AdminPasswordChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminPasswordChange', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['currentPassword', 'newPassword']);
      final val = AdminPasswordChange(
        currentPassword: $checkedConvert('currentPassword', (v) => v as String),
        newPassword: $checkedConvert('newPassword', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdminPasswordChangeToJson(
  AdminPasswordChange instance,
) => <String, dynamic>{
  'currentPassword': instance.currentPassword,
  'newPassword': instance.newPassword,
};
