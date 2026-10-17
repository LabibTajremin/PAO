// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SettingUpdateCWProxy {
  SettingUpdate value(String value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SettingUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SettingUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  SettingUpdate call({String value});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSettingUpdate.copyWith(...)` or call `instanceOfSettingUpdate.copyWith.fieldName(value)` for a single field.
class _$SettingUpdateCWProxyImpl implements _$SettingUpdateCWProxy {
  const _$SettingUpdateCWProxyImpl(this._value);

  final SettingUpdate _value;

  @override
  SettingUpdate value(String value) => call(value: value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SettingUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SettingUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SettingUpdate call({Object? value = const $CopyWithPlaceholder()}) {
    return SettingUpdate(
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
    );
  }
}

extension $SettingUpdateCopyWith on SettingUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSettingUpdate.copyWith(...)` or `instanceOfSettingUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SettingUpdateCWProxy get copyWith => _$SettingUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingUpdate _$SettingUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SettingUpdate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['value']);
      final val = SettingUpdate(
        value: $checkedConvert('value', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SettingUpdateToJson(SettingUpdate instance) =>
    <String, dynamic>{'value': instance.value};
