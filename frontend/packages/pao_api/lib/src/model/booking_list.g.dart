// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingListCWProxy {
  BookingList items(List<BookingSummary> items);

  BookingList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingList(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingList call({List<BookingSummary> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingList.copyWith(...)` or call `instanceOfBookingList.copyWith.fieldName(value)` for a single field.
class _$BookingListCWProxyImpl implements _$BookingListCWProxy {
  const _$BookingListCWProxyImpl(this._value);

  final BookingList _value;

  @override
  BookingList items(List<BookingSummary> items) => call(items: items);

  @override
  BookingList nextCursor(String? nextCursor) => call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return BookingList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingSummary>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $BookingListCopyWith on BookingList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingList.copyWith(...)` or `instanceOfBookingList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingListCWProxy get copyWith => _$BookingListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingList _$BookingListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BookingList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = BookingList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$BookingListToJson(BookingList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
