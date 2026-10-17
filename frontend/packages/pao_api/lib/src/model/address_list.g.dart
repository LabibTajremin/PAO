// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddressListCWProxy {
  AddressList items(List<Address> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddressList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddressList(...).copyWith(id: 12, name: "My name")
  /// ```
  AddressList call({List<Address> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddressList.copyWith(...)` or call `instanceOfAddressList.copyWith.fieldName(value)` for a single field.
class _$AddressListCWProxyImpl implements _$AddressListCWProxy {
  const _$AddressListCWProxyImpl(this._value);

  final AddressList _value;

  @override
  AddressList items(List<Address> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddressList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddressList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AddressList call({Object? items = const $CopyWithPlaceholder()}) {
    return AddressList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Address>,
    );
  }
}

extension $AddressListCopyWith on AddressList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddressList.copyWith(...)` or `instanceOfAddressList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddressListCWProxy get copyWith => _$AddressListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressList _$AddressListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddressList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = AddressList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Address.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AddressListToJson(AddressList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
