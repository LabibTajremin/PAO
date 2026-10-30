// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmergencyContactInputCWProxy {
  EmergencyContactInput name(String name);

  EmergencyContactInput relation(String relation);

  EmergencyContactInput phone(String phone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmergencyContactInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmergencyContactInput(...).copyWith(id: 12, name: "My name")
  /// ```
  EmergencyContactInput call({String name, String relation, String phone});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEmergencyContactInput.copyWith(...)` or call `instanceOfEmergencyContactInput.copyWith.fieldName(value)` for a single field.
class _$EmergencyContactInputCWProxyImpl
    implements _$EmergencyContactInputCWProxy {
  const _$EmergencyContactInputCWProxyImpl(this._value);

  final EmergencyContactInput _value;

  @override
  EmergencyContactInput name(String name) => call(name: name);

  @override
  EmergencyContactInput relation(String relation) => call(relation: relation);

  @override
  EmergencyContactInput phone(String phone) => call(phone: phone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EmergencyContactInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EmergencyContactInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EmergencyContactInput call({
    Object? name = const $CopyWithPlaceholder(),
    Object? relation = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
  }) {
    return EmergencyContactInput(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      relation: relation == const $CopyWithPlaceholder() || relation == null
          ? _value.relation
          // ignore: cast_nullable_to_non_nullable
          : relation as String,
      phone: phone == const $CopyWithPlaceholder() || phone == null
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
    );
  }
}

extension $EmergencyContactInputCopyWith on EmergencyContactInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEmergencyContactInput.copyWith(...)` or `instanceOfEmergencyContactInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmergencyContactInputCWProxy get copyWith =>
      _$EmergencyContactInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyContactInput _$EmergencyContactInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EmergencyContactInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'relation', 'phone']);
  final val = EmergencyContactInput(
    name: $checkedConvert('name', (v) => v as String),
    relation: $checkedConvert('relation', (v) => v as String),
    phone: $checkedConvert('phone', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$EmergencyContactInputToJson(
  EmergencyContactInput instance,
) => <String, dynamic>{
  'name': instance.name,
  'relation': instance.relation,
  'phone': instance.phone,
};
