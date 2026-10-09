// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddressInputCWProxy {
  AddressInput label(AddressLabel label);

  AddressInput line1(String line1);

  AddressInput line2(String? line2);

  AddressInput area(String? area);

  AddressInput location(Point location);

  AddressInput isDefault(bool? isDefault);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddressInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddressInput(...).copyWith(id: 12, name: "My name")
  /// ```
  AddressInput call({
    AddressLabel label,
    String line1,
    String? line2,
    String? area,
    Point location,
    bool? isDefault,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddressInput.copyWith(...)` or call `instanceOfAddressInput.copyWith.fieldName(value)` for a single field.
class _$AddressInputCWProxyImpl implements _$AddressInputCWProxy {
  const _$AddressInputCWProxyImpl(this._value);

  final AddressInput _value;

  @override
  AddressInput label(AddressLabel label) => call(label: label);

  @override
  AddressInput line1(String line1) => call(line1: line1);

  @override
  AddressInput line2(String? line2) => call(line2: line2);

  @override
  AddressInput area(String? area) => call(area: area);

  @override
  AddressInput location(Point location) => call(location: location);

  @override
  AddressInput isDefault(bool? isDefault) => call(isDefault: isDefault);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddressInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddressInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AddressInput call({
    Object? label = const $CopyWithPlaceholder(),
    Object? line1 = const $CopyWithPlaceholder(),
    Object? line2 = const $CopyWithPlaceholder(),
    Object? area = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? isDefault = const $CopyWithPlaceholder(),
  }) {
    return AddressInput(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as AddressLabel,
      line1: line1 == const $CopyWithPlaceholder() || line1 == null
          ? _value.line1
          // ignore: cast_nullable_to_non_nullable
          : line1 as String,
      line2: line2 == const $CopyWithPlaceholder()
          ? _value.line2
          // ignore: cast_nullable_to_non_nullable
          : line2 as String?,
      area: area == const $CopyWithPlaceholder()
          ? _value.area
          // ignore: cast_nullable_to_non_nullable
          : area as String?,
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as Point,
      isDefault: isDefault == const $CopyWithPlaceholder()
          ? _value.isDefault
          // ignore: cast_nullable_to_non_nullable
          : isDefault as bool?,
    );
  }
}

extension $AddressInputCopyWith on AddressInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddressInput.copyWith(...)` or `instanceOfAddressInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddressInputCWProxy get copyWith => _$AddressInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressInput _$AddressInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddressInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['label', 'line1', 'location']);
      final val = AddressInput(
        label: $checkedConvert(
          'label',
          (v) => $enumDecode(_$AddressLabelEnumMap, v),
        ),
        line1: $checkedConvert('line1', (v) => v as String),
        line2: $checkedConvert('line2', (v) => v as String?),
        area: $checkedConvert('area', (v) => v as String?),
        location: $checkedConvert(
          'location',
          (v) => Point.fromJson(v as Map<String, dynamic>),
        ),
        isDefault: $checkedConvert('isDefault', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$AddressInputToJson(AddressInput instance) =>
    <String, dynamic>{
      'label': _$AddressLabelEnumMap[instance.label]!,
      'line1': instance.line1,
      'line2': ?instance.line2,
      'area': ?instance.area,
      'location': instance.location.toJson(),
      'isDefault': ?instance.isDefault,
    };

const _$AddressLabelEnumMap = {
  AddressLabel.home: 'home',
  AddressLabel.office: 'office',
  AddressLabel.other: 'other',
};
