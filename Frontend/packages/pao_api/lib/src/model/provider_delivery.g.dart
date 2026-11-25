// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_delivery.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderDeliveryCWProxy {
  ProviderDelivery subscriptionId(String subscriptionId);

  ProviderDelivery number(String number);

  ProviderDelivery date(String date);

  ProviderDelivery window(DeliveryWindow window);

  ProviderDelivery status(DeliveryStatus status);

  ProviderDelivery serviceName(LocalizedText serviceName);

  ProviderDelivery items(List<BookingItemInput> items);

  ProviderDelivery total(int total);

  ProviderDelivery address(BookingAddress address);

  ProviderDelivery customerName(String? customerName);

  ProviderDelivery bookingId(String? bookingId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderDelivery(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderDelivery(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderDelivery call({
    String subscriptionId,
    String number,
    String date,
    DeliveryWindow window,
    DeliveryStatus status,
    LocalizedText serviceName,
    List<BookingItemInput> items,
    int total,
    BookingAddress address,
    String? customerName,
    String? bookingId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderDelivery.copyWith(...)` or call `instanceOfProviderDelivery.copyWith.fieldName(value)` for a single field.
class _$ProviderDeliveryCWProxyImpl implements _$ProviderDeliveryCWProxy {
  const _$ProviderDeliveryCWProxyImpl(this._value);

  final ProviderDelivery _value;

  @override
  ProviderDelivery subscriptionId(String subscriptionId) =>
      call(subscriptionId: subscriptionId);

  @override
  ProviderDelivery number(String number) => call(number: number);

  @override
  ProviderDelivery date(String date) => call(date: date);

  @override
  ProviderDelivery window(DeliveryWindow window) => call(window: window);

  @override
  ProviderDelivery status(DeliveryStatus status) => call(status: status);

  @override
  ProviderDelivery serviceName(LocalizedText serviceName) =>
      call(serviceName: serviceName);

  @override
  ProviderDelivery items(List<BookingItemInput> items) => call(items: items);

  @override
  ProviderDelivery total(int total) => call(total: total);

  @override
  ProviderDelivery address(BookingAddress address) => call(address: address);

  @override
  ProviderDelivery customerName(String? customerName) =>
      call(customerName: customerName);

  @override
  ProviderDelivery bookingId(String? bookingId) => call(bookingId: bookingId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderDelivery(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderDelivery(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderDelivery call({
    Object? subscriptionId = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? date = const $CopyWithPlaceholder(),
    Object? window = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? serviceName = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? customerName = const $CopyWithPlaceholder(),
    Object? bookingId = const $CopyWithPlaceholder(),
  }) {
    return ProviderDelivery(
      subscriptionId:
          subscriptionId == const $CopyWithPlaceholder() ||
              subscriptionId == null
          ? _value.subscriptionId
          // ignore: cast_nullable_to_non_nullable
          : subscriptionId as String,
      number: number == const $CopyWithPlaceholder() || number == null
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as String,
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      window: window == const $CopyWithPlaceholder() || window == null
          ? _value.window
          // ignore: cast_nullable_to_non_nullable
          : window as DeliveryWindow,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as DeliveryStatus,
      serviceName:
          serviceName == const $CopyWithPlaceholder() || serviceName == null
          ? _value.serviceName
          // ignore: cast_nullable_to_non_nullable
          : serviceName as LocalizedText,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItemInput>,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as BookingAddress,
      customerName: customerName == const $CopyWithPlaceholder()
          ? _value.customerName
          // ignore: cast_nullable_to_non_nullable
          : customerName as String?,
      bookingId: bookingId == const $CopyWithPlaceholder()
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String?,
    );
  }
}

extension $ProviderDeliveryCopyWith on ProviderDelivery {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderDelivery.copyWith(...)` or `instanceOfProviderDelivery.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderDeliveryCWProxy get copyWith => _$ProviderDeliveryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderDelivery _$ProviderDeliveryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderDelivery', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'subscriptionId',
          'number',
          'date',
          'window',
          'status',
          'serviceName',
          'items',
          'total',
          'address',
        ],
      );
      final val = ProviderDelivery(
        subscriptionId: $checkedConvert('subscriptionId', (v) => v as String),
        number: $checkedConvert('number', (v) => v as String),
        date: $checkedConvert('date', (v) => v as String),
        window: $checkedConvert(
          'window',
          (v) => DeliveryWindow.fromJson(v as Map<String, dynamic>),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$DeliveryStatusEnumMap, v),
        ),
        serviceName: $checkedConvert(
          'serviceName',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingItemInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        address: $checkedConvert(
          'address',
          (v) => BookingAddress.fromJson(v as Map<String, dynamic>),
        ),
        customerName: $checkedConvert('customerName', (v) => v as String?),
        bookingId: $checkedConvert('bookingId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ProviderDeliveryToJson(ProviderDelivery instance) =>
    <String, dynamic>{
      'subscriptionId': instance.subscriptionId,
      'number': instance.number,
      'date': instance.date,
      'window': instance.window.toJson(),
      'status': _$DeliveryStatusEnumMap[instance.status]!,
      'serviceName': instance.serviceName.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'address': instance.address.toJson(),
      'customerName': ?instance.customerName,
      'bookingId': ?instance.bookingId,
    };

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.scheduled: 'scheduled',
  DeliveryStatus.preparing: 'preparing',
  DeliveryStatus.outForDelivery: 'out_for_delivery',
  DeliveryStatus.delivered: 'delivered',
  DeliveryStatus.skipped: 'skipped',
  DeliveryStatus.declined: 'declined',
  DeliveryStatus.cancelled: 'cancelled',
};
