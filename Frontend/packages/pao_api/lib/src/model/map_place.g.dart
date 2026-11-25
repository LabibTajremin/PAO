// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_place.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MapPlaceCWProxy {
  MapPlace id(String id);

  MapPlace kind(MapPlaceKindEnum kind);

  MapPlace title(String title);

  MapPlace area(String? area);

  MapPlace location(Point location);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MapPlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MapPlace(...).copyWith(id: 12, name: "My name")
  /// ```
  MapPlace call({
    String id,
    MapPlaceKindEnum kind,
    String title,
    String? area,
    Point location,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMapPlace.copyWith(...)` or call `instanceOfMapPlace.copyWith.fieldName(value)` for a single field.
class _$MapPlaceCWProxyImpl implements _$MapPlaceCWProxy {
  const _$MapPlaceCWProxyImpl(this._value);

  final MapPlace _value;

  @override
  MapPlace id(String id) => call(id: id);

  @override
  MapPlace kind(MapPlaceKindEnum kind) => call(kind: kind);

  @override
  MapPlace title(String title) => call(title: title);

  @override
  MapPlace area(String? area) => call(area: area);

  @override
  MapPlace location(Point location) => call(location: location);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MapPlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MapPlace(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MapPlace call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? area = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
  }) {
    return MapPlace(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as MapPlaceKindEnum,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      area: area == const $CopyWithPlaceholder()
          ? _value.area
          // ignore: cast_nullable_to_non_nullable
          : area as String?,
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as Point,
    );
  }
}

extension $MapPlaceCopyWith on MapPlace {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMapPlace.copyWith(...)` or `instanceOfMapPlace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MapPlaceCWProxy get copyWith => _$MapPlaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapPlace _$MapPlaceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MapPlace', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'kind', 'title', 'location']);
      final val = MapPlace(
        id: $checkedConvert('id', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$MapPlaceKindEnumEnumMap, v),
        ),
        title: $checkedConvert('title', (v) => v as String),
        area: $checkedConvert('area', (v) => v as String?),
        location: $checkedConvert(
          'location',
          (v) => Point.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MapPlaceToJson(MapPlace instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$MapPlaceKindEnumEnumMap[instance.kind]!,
  'title': instance.title,
  'area': ?instance.area,
  'location': instance.location.toJson(),
};

const _$MapPlaceKindEnumEnumMap = {
  MapPlaceKindEnum.area: 'area',
  MapPlaceKindEnum.street: 'street',
  MapPlaceKindEnum.place: 'place',
  MapPlaceKindEnum.address: 'address',
};
