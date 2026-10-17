// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SettingCWProxy {
  Setting key(String key);

  Setting value(String value);

  Setting type(SettingTypeEnum type);

  Setting description(String description);

  Setting updatedAt(DateTime? updatedAt);

  Setting updatedBy(String? updatedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Setting(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Setting(...).copyWith(id: 12, name: "My name")
  /// ```
  Setting call({
    String key,
    String value,
    SettingTypeEnum type,
    String description,
    DateTime? updatedAt,
    String? updatedBy,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetting.copyWith(...)` or call `instanceOfSetting.copyWith.fieldName(value)` for a single field.
class _$SettingCWProxyImpl implements _$SettingCWProxy {
  const _$SettingCWProxyImpl(this._value);

  final Setting _value;

  @override
  Setting key(String key) => call(key: key);

  @override
  Setting value(String value) => call(value: value);

  @override
  Setting type(SettingTypeEnum type) => call(type: type);

  @override
  Setting description(String description) => call(description: description);

  @override
  Setting updatedAt(DateTime? updatedAt) => call(updatedAt: updatedAt);

  @override
  Setting updatedBy(String? updatedBy) => call(updatedBy: updatedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Setting(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Setting(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Setting call({
    Object? key = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? updatedBy = const $CopyWithPlaceholder(),
  }) {
    return Setting(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as SettingTypeEnum,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime?,
      updatedBy: updatedBy == const $CopyWithPlaceholder()
          ? _value.updatedBy
          // ignore: cast_nullable_to_non_nullable
          : updatedBy as String?,
    );
  }
}

extension $SettingCopyWith on Setting {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetting.copyWith(...)` or `instanceOfSetting.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SettingCWProxy get copyWith => _$SettingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Setting _$SettingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Setting', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['key', 'value', 'type', 'description'],
      );
      final val = Setting(
        key: $checkedConvert('key', (v) => v as String),
        value: $checkedConvert('value', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$SettingTypeEnumEnumMap, v),
        ),
        description: $checkedConvert('description', (v) => v as String),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        updatedBy: $checkedConvert('updatedBy', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SettingToJson(Setting instance) => <String, dynamic>{
  'key': instance.key,
  'value': instance.value,
  'type': _$SettingTypeEnumEnumMap[instance.type]!,
  'description': instance.description,
  'updatedAt': ?instance.updatedAt?.toIso8601String(),
  'updatedBy': ?instance.updatedBy,
};

const _$SettingTypeEnumEnumMap = {
  SettingTypeEnum.integer: 'integer',
  SettingTypeEnum.number: 'number',
  SettingTypeEnum.boolean: 'boolean',
  SettingTypeEnum.string: 'string',
  SettingTypeEnum.geojson: 'geojson',
};
