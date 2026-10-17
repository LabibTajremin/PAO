// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_party.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingPartyCWProxy {
  BookingParty id(String id);

  BookingParty name(String name);

  BookingParty photoUrl(String? photoUrl);

  BookingParty phone(String? phone);

  BookingParty badge(Badge? badge);

  BookingParty rating(double? rating);

  BookingParty ratingCount(int? ratingCount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingParty(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingParty(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingParty call({
    String id,
    String name,
    String? photoUrl,
    String? phone,
    Badge? badge,
    double? rating,
    int? ratingCount,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingParty.copyWith(...)` or call `instanceOfBookingParty.copyWith.fieldName(value)` for a single field.
class _$BookingPartyCWProxyImpl implements _$BookingPartyCWProxy {
  const _$BookingPartyCWProxyImpl(this._value);

  final BookingParty _value;

  @override
  BookingParty id(String id) => call(id: id);

  @override
  BookingParty name(String name) => call(name: name);

  @override
  BookingParty photoUrl(String? photoUrl) => call(photoUrl: photoUrl);

  @override
  BookingParty phone(String? phone) => call(phone: phone);

  @override
  BookingParty badge(Badge? badge) => call(badge: badge);

  @override
  BookingParty rating(double? rating) => call(rating: rating);

  @override
  BookingParty ratingCount(int? ratingCount) => call(ratingCount: ratingCount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingParty(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingParty(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingParty call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? badge = const $CopyWithPlaceholder(),
    Object? rating = const $CopyWithPlaceholder(),
    Object? ratingCount = const $CopyWithPlaceholder(),
  }) {
    return BookingParty(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      photoUrl: photoUrl == const $CopyWithPlaceholder()
          ? _value.photoUrl
          // ignore: cast_nullable_to_non_nullable
          : photoUrl as String?,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      badge: badge == const $CopyWithPlaceholder()
          ? _value.badge
          // ignore: cast_nullable_to_non_nullable
          : badge as Badge?,
      rating: rating == const $CopyWithPlaceholder()
          ? _value.rating
          // ignore: cast_nullable_to_non_nullable
          : rating as double?,
      ratingCount: ratingCount == const $CopyWithPlaceholder()
          ? _value.ratingCount
          // ignore: cast_nullable_to_non_nullable
          : ratingCount as int?,
    );
  }
}

extension $BookingPartyCopyWith on BookingParty {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingParty.copyWith(...)` or `instanceOfBookingParty.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingPartyCWProxy get copyWith => _$BookingPartyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingParty _$BookingPartyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BookingParty', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name']);
      final val = BookingParty(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        photoUrl: $checkedConvert('photoUrl', (v) => v as String?),
        phone: $checkedConvert('phone', (v) => v as String?),
        badge: $checkedConvert(
          'badge',
          (v) => $enumDecodeNullable(_$BadgeEnumMap, v),
        ),
        rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
        ratingCount: $checkedConvert(
          'ratingCount',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BookingPartyToJson(BookingParty instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'photoUrl': ?instance.photoUrl,
      'phone': ?instance.phone,
      'badge': ?_$BadgeEnumMap[instance.badge],
      'rating': ?instance.rating,
      'ratingCount': ?instance.ratingCount,
    };

const _$BadgeEnumMap = {
  Badge.none: 'none',
  Badge.verified: 'verified',
  Badge.verifiedPro: 'verified_pro',
};
