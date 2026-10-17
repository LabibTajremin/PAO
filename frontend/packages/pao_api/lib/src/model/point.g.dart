// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PointCWProxy {
  Point lat(double lat);

  Point lng(double lng);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Point(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Point(...).copyWith(id: 12, name: "My name")
  /// ```
  Point call({double lat, double lng});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPoint.copyWith(...)` or call `instanceOfPoint.copyWith.fieldName(value)` for a single field.
class _$PointCWProxyImpl implements _$PointCWProxy {
  const _$PointCWProxyImpl(this._value);

  final Point _value;

  @override
  Point lat(double lat) => call(lat: lat);

  @override
  Point lng(double lng) => call(lng: lng);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Point(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Point(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Point call({
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
  }) {
    return Point(
      lat: lat == const $CopyWithPlaceholder() || lat == null
          ? _value.lat
          // ignore: cast_nullable_to_non_nullable
          : lat as double,
      lng: lng == const $CopyWithPlaceholder() || lng == null
          ? _value.lng
          // ignore: cast_nullable_to_non_nullable
          : lng as double,
    );
  }
}

extension $PointCopyWith on Point {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPoint.copyWith(...)` or `instanceOfPoint.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PointCWProxy get copyWith => _$PointCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Point _$PointFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Point', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['lat', 'lng']);
      final val = Point(
        lat: $checkedConvert('lat', (v) => (v as num).toDouble()),
        lng: $checkedConvert('lng', (v) => (v as num).toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$PointToJson(Point instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};
