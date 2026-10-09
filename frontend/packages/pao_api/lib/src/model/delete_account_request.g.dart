// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteAccountRequestCWProxy {
  DeleteAccountRequest code(String code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteAccountRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteAccountRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  DeleteAccountRequest call({String code});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeleteAccountRequest.copyWith(...)` or call `instanceOfDeleteAccountRequest.copyWith.fieldName(value)` for a single field.
class _$DeleteAccountRequestCWProxyImpl
    implements _$DeleteAccountRequestCWProxy {
  const _$DeleteAccountRequestCWProxyImpl(this._value);

  final DeleteAccountRequest _value;

  @override
  DeleteAccountRequest code(String code) => call(code: code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteAccountRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteAccountRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeleteAccountRequest call({Object? code = const $CopyWithPlaceholder()}) {
    return DeleteAccountRequest(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $DeleteAccountRequestCopyWith on DeleteAccountRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeleteAccountRequest.copyWith(...)` or `instanceOfDeleteAccountRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteAccountRequestCWProxy get copyWith =>
      _$DeleteAccountRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteAccountRequest _$DeleteAccountRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeleteAccountRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code']);
  final val = DeleteAccountRequest(
    code: $checkedConvert('code', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$DeleteAccountRequestToJson(
  DeleteAccountRequest instance,
) => <String, dynamic>{'code': instance.code};
