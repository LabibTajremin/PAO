// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact_verify_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmergencyContactVerifyInputCWProxy {
  EmergencyContactVerifyInput code(String code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmergencyContactVerifyInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmergencyContactVerifyInput(...).copyWith(id: 12, name: "My name")
  /// ```
  EmergencyContactVerifyInput call({String code});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEmergencyContactVerifyInput.copyWith(...)` or call `instanceOfEmergencyContactVerifyInput.copyWith.fieldName(value)` for a single field.
class _$EmergencyContactVerifyInputCWProxyImpl
    implements _$EmergencyContactVerifyInputCWProxy {
  const _$EmergencyContactVerifyInputCWProxyImpl(this._value);

  final EmergencyContactVerifyInput _value;

  @override
  EmergencyContactVerifyInput code(String code) => call(code: code);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmergencyContactVerifyInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmergencyContactVerifyInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EmergencyContactVerifyInput call({
    Object? code = const $CopyWithPlaceholder(),
  }) {
    return EmergencyContactVerifyInput(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $EmergencyContactVerifyInputCopyWith on EmergencyContactVerifyInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEmergencyContactVerifyInput.copyWith(...)` or `instanceOfEmergencyContactVerifyInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmergencyContactVerifyInputCWProxy get copyWith =>
      _$EmergencyContactVerifyInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyContactVerifyInput _$EmergencyContactVerifyInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EmergencyContactVerifyInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['code']);
  final val = EmergencyContactVerifyInput(
    code: $checkedConvert('code', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$EmergencyContactVerifyInputToJson(
  EmergencyContactVerifyInput instance,
) => <String, dynamic>{'code': instance.code};
