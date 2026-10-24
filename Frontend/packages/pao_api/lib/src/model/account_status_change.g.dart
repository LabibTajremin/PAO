// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_status_change.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountStatusChangeCWProxy {
  AccountStatusChange status(AccountStatusChangeStatusEnum status);

  AccountStatusChange reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AccountStatusChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AccountStatusChange(...).copyWith(id: 12, name: "My name")
  /// ```
  AccountStatusChange call({
    AccountStatusChangeStatusEnum status,
    String reason,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAccountStatusChange.copyWith(...)` or call `instanceOfAccountStatusChange.copyWith.fieldName(value)` for a single field.
class _$AccountStatusChangeCWProxyImpl implements _$AccountStatusChangeCWProxy {
  const _$AccountStatusChangeCWProxyImpl(this._value);

  final AccountStatusChange _value;

  @override
  AccountStatusChange status(AccountStatusChangeStatusEnum status) =>
      call(status: status);

  @override
  AccountStatusChange reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AccountStatusChange(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AccountStatusChange(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AccountStatusChange call({
    Object? status = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return AccountStatusChange(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AccountStatusChangeStatusEnum,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $AccountStatusChangeCopyWith on AccountStatusChange {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAccountStatusChange.copyWith(...)` or `instanceOfAccountStatusChange.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountStatusChangeCWProxy get copyWith =>
      _$AccountStatusChangeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountStatusChange _$AccountStatusChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountStatusChange', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status', 'reason']);
      final val = AccountStatusChange(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AccountStatusChangeStatusEnumEnumMap, v),
        ),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AccountStatusChangeToJson(
  AccountStatusChange instance,
) => <String, dynamic>{
  'status': _$AccountStatusChangeStatusEnumEnumMap[instance.status]!,
  'reason': instance.reason,
};

const _$AccountStatusChangeStatusEnumEnumMap = {
  AccountStatusChangeStatusEnum.active: 'active',
  AccountStatusChangeStatusEnum.suspended: 'suspended',
  AccountStatusChangeStatusEnum.banned: 'banned',
};
