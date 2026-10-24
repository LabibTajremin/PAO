// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_address.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingAddressCWProxy {
  BookingAddress area(String area);

  BookingAddress line1(String? line1);

  BookingAddress line2(String? line2);

  BookingAddress location(Point? location);

  BookingAddress distanceM(int? distanceM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingAddress(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingAddress(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingAddress call({
    String area,
    String? line1,
    String? line2,
    Point? location,
    int? distanceM,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingAddress.copyWith(...)` or call `instanceOfBookingAddress.copyWith.fieldName(value)` for a single field.
class _$BookingAddressCWProxyImpl implements _$BookingAddressCWProxy {
  const _$BookingAddressCWProxyImpl(this._value);

  final BookingAddress _value;

  @override
  BookingAddress area(String area) => call(area: area);

  @override
  BookingAddress line1(String? line1) => call(line1: line1);

  @override
  BookingAddress line2(String? line2) => call(line2: line2);

  @override
  BookingAddress location(Point? location) => call(location: location);

  @override
  BookingAddress distanceM(int? distanceM) => call(distanceM: distanceM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingAddress(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingAddress(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingAddress call({
    Object? area = const $CopyWithPlaceholder(),
    Object? line1 = const $CopyWithPlaceholder(),
    Object? line2 = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? distanceM = const $CopyWithPlaceholder(),
  }) {
    return BookingAddress(
      area: area == const $CopyWithPlaceholder() || area == null
          ? _value.area
          // ignore: cast_nullable_to_non_nullable
          : area as String,
      line1: line1 == const $CopyWithPlaceholder()
          ? _value.line1
          // ignore: cast_nullable_to_non_nullable
          : line1 as String?,
      line2: line2 == const $CopyWithPlaceholder()
          ? _value.line2
          // ignore: cast_nullable_to_non_nullable
          : line2 as String?,
      location: location == const $CopyWithPlaceholder()
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as Point?,
      distanceM: distanceM == const $CopyWithPlaceholder()
          ? _value.distanceM
          // ignore: cast_nullable_to_non_nullable
          : distanceM as int?,
    );
  }
}

extension $BookingAddressCopyWith on BookingAddress {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingAddress.copyWith(...)` or `instanceOfBookingAddress.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingAddressCWProxy get copyWith => _$BookingAddressCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingAddress _$BookingAddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BookingAddress', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['area']);
      final val = BookingAddress(
        area: $checkedConvert('area', (v) => v as String),
        line1: $checkedConvert('line1', (v) => v as String?),
        line2: $checkedConvert('line2', (v) => v as String?),
        location: $checkedConvert(
          'location',
          (v) => v == null ? null : Point.fromJson(v as Map<String, dynamic>),
        ),
        distanceM: $checkedConvert('distanceM', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$BookingAddressToJson(BookingAddress instance) =>
    <String, dynamic>{
      'area': instance.area,
      'line1': ?instance.line1,
      'line2': ?instance.line2,
      'location': ?instance.location?.toJson(),
      'distanceM': ?instance.distanceM,
    };
