// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddressCWProxy {
  Address label(AddressLabel label);

  Address line1(String line1);

  Address line2(String? line2);

  Address area(String? area);

  Address location(Point location);

  Address isDefault(bool? isDefault);

  Address id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Address(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Address(...).copyWith(id: 12, name: "My name")
  /// ```
  Address call({
    AddressLabel label,
    String line1,
    String? line2,
    String? area,
    Point location,
    bool? isDefault,
    String id,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddress.copyWith(...)` or call `instanceOfAddress.copyWith.fieldName(value)` for a single field.
class _$AddressCWProxyImpl implements _$AddressCWProxy {
  const _$AddressCWProxyImpl(this._value);

  final Address _value;

  @override
  Address label(AddressLabel label) => call(label: label);

  @override
  Address line1(String line1) => call(line1: line1);

  @override
  Address line2(String? line2) => call(line2: line2);

  @override
  Address area(String? area) => call(area: area);

  @override
  Address location(Point location) => call(location: location);

  @override
  Address isDefault(bool? isDefault) => call(isDefault: isDefault);

  @override
  Address id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Address(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Address(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Address call({
    Object? label = const $CopyWithPlaceholder(),
    Object? line1 = const $CopyWithPlaceholder(),
    Object? line2 = const $CopyWithPlaceholder(),
    Object? area = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? isDefault = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return Address(
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
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
    );
  }
}

extension $AddressCopyWith on Address {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddress.copyWith(...)` or `instanceOfAddress.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddressCWProxy get copyWith => _$AddressCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Address',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['label', 'line1', 'location', 'id']);
    final val = Address(
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
      id: $checkedConvert('id', (v) => v as String),
    );
    return val;
  },
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'label': _$AddressLabelEnumMap[instance.label]!,
  'line1': instance.line1,
  'line2': ?instance.line2,
  'area': ?instance.area,
  'location': instance.location.toJson(),
  'isDefault': ?instance.isDefault,
  'id': instance.id,
};

const _$AddressLabelEnumMap = {
  AddressLabel.home: 'home',
  AddressLabel.office: 'office',
  AddressLabel.other: 'other',
};
