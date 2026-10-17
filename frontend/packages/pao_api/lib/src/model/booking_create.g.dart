// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingCreateCWProxy {
  BookingCreate providerId(String providerId);

  BookingCreate serviceId(String serviceId);

  BookingCreate items(List<BookingItemInput> items);

  BookingCreate timing(Timing timing);

  BookingCreate scheduledAt(DateTime? scheduledAt);

  BookingCreate addressId(String addressId);

  BookingCreate note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingCreate call({
    String providerId,
    String serviceId,
    List<BookingItemInput> items,
    Timing timing,
    DateTime? scheduledAt,
    String addressId,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingCreate.copyWith(...)` or call `instanceOfBookingCreate.copyWith.fieldName(value)` for a single field.
class _$BookingCreateCWProxyImpl implements _$BookingCreateCWProxy {
  const _$BookingCreateCWProxyImpl(this._value);

  final BookingCreate _value;

  @override
  BookingCreate providerId(String providerId) => call(providerId: providerId);

  @override
  BookingCreate serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  BookingCreate items(List<BookingItemInput> items) => call(items: items);

  @override
  BookingCreate timing(Timing timing) => call(timing: timing);

  @override
  BookingCreate scheduledAt(DateTime? scheduledAt) =>
      call(scheduledAt: scheduledAt);

  @override
  BookingCreate addressId(String addressId) => call(addressId: addressId);

  @override
  BookingCreate note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingCreate call({
    Object? providerId = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? timing = const $CopyWithPlaceholder(),
    Object? scheduledAt = const $CopyWithPlaceholder(),
    Object? addressId = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return BookingCreate(
      providerId:
          providerId == const $CopyWithPlaceholder() || providerId == null
          ? _value.providerId
          // ignore: cast_nullable_to_non_nullable
          : providerId as String,
      serviceId: serviceId == const $CopyWithPlaceholder() || serviceId == null
          ? _value.serviceId
          // ignore: cast_nullable_to_non_nullable
          : serviceId as String,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItemInput>,
      timing: timing == const $CopyWithPlaceholder() || timing == null
          ? _value.timing
          // ignore: cast_nullable_to_non_nullable
          : timing as Timing,
      scheduledAt: scheduledAt == const $CopyWithPlaceholder()
          ? _value.scheduledAt
          // ignore: cast_nullable_to_non_nullable
          : scheduledAt as DateTime?,
      addressId: addressId == const $CopyWithPlaceholder() || addressId == null
          ? _value.addressId
          // ignore: cast_nullable_to_non_nullable
          : addressId as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $BookingCreateCopyWith on BookingCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingCreate.copyWith(...)` or `instanceOfBookingCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingCreateCWProxy get copyWith => _$BookingCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingCreate _$BookingCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BookingCreate', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'providerId',
          'serviceId',
          'items',
          'timing',
          'addressId',
        ],
      );
      final val = BookingCreate(
        providerId: $checkedConvert('providerId', (v) => v as String),
        serviceId: $checkedConvert('serviceId', (v) => v as String),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingItemInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        timing: $checkedConvert(
          'timing',
          (v) => $enumDecode(_$TimingEnumMap, v),
        ),
        scheduledAt: $checkedConvert(
          'scheduledAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        addressId: $checkedConvert('addressId', (v) => v as String),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$BookingCreateToJson(BookingCreate instance) =>
    <String, dynamic>{
      'providerId': instance.providerId,
      'serviceId': instance.serviceId,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'timing': _$TimingEnumMap[instance.timing]!,
      'scheduledAt': ?instance.scheduledAt?.toIso8601String(),
      'addressId': instance.addressId,
      'note': ?instance.note,
    };

const _$TimingEnumMap = {Timing.asap: 'asap', Timing.scheduled: 'scheduled'};
