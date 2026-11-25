// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_place_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MapPlaceListCWProxy {
  MapPlaceList items(List<MapPlace> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MapPlaceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MapPlaceList(...).copyWith(id: 12, name: "My name")
  /// ```
  MapPlaceList call({List<MapPlace> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMapPlaceList.copyWith(...)` or call `instanceOfMapPlaceList.copyWith.fieldName(value)` for a single field.
class _$MapPlaceListCWProxyImpl implements _$MapPlaceListCWProxy {
  const _$MapPlaceListCWProxyImpl(this._value);

  final MapPlaceList _value;

  @override
  MapPlaceList items(List<MapPlace> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MapPlaceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MapPlaceList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MapPlaceList call({Object? items = const $CopyWithPlaceholder()}) {
    return MapPlaceList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<MapPlace>,
    );
  }
}

extension $MapPlaceListCopyWith on MapPlaceList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMapPlaceList.copyWith(...)` or `instanceOfMapPlaceList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MapPlaceListCWProxy get copyWith => _$MapPlaceListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapPlaceList _$MapPlaceListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MapPlaceList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = MapPlaceList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => MapPlace.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MapPlaceListToJson(MapPlaceList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
