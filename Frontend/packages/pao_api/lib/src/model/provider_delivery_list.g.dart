// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_delivery_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderDeliveryListCWProxy {
  ProviderDeliveryList items(List<ProviderDelivery> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderDeliveryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderDeliveryList(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderDeliveryList call({List<ProviderDelivery> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderDeliveryList.copyWith(...)` or call `instanceOfProviderDeliveryList.copyWith.fieldName(value)` for a single field.
class _$ProviderDeliveryListCWProxyImpl
    implements _$ProviderDeliveryListCWProxy {
  const _$ProviderDeliveryListCWProxyImpl(this._value);

  final ProviderDeliveryList _value;

  @override
  ProviderDeliveryList items(List<ProviderDelivery> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderDeliveryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderDeliveryList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderDeliveryList call({Object? items = const $CopyWithPlaceholder()}) {
    return ProviderDeliveryList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ProviderDelivery>,
    );
  }
}

extension $ProviderDeliveryListCopyWith on ProviderDeliveryList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderDeliveryList.copyWith(...)` or `instanceOfProviderDeliveryList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderDeliveryListCWProxy get copyWith =>
      _$ProviderDeliveryListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderDeliveryList _$ProviderDeliveryListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProviderDeliveryList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ProviderDeliveryList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => ProviderDelivery.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ProviderDeliveryListToJson(
  ProviderDeliveryList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
