// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReceiptCWProxy {
  Receipt bookingId(String bookingId);

  Receipt number(String number);

  Receipt completedAt(DateTime completedAt);

  Receipt serviceName(LocalizedText serviceName);

  Receipt providerName(String providerName);

  Receipt customerName(String customerName);

  Receipt area(String? area);

  Receipt items(List<BookingItem> items);

  Receipt total(int total);

  Receipt paymentMethod(ReceiptPaymentMethodEnum paymentMethod);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Receipt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Receipt(...).copyWith(id: 12, name: "My name")
  /// ```
  Receipt call({
    String bookingId,
    String number,
    DateTime completedAt,
    LocalizedText serviceName,
    String providerName,
    String customerName,
    String? area,
    List<BookingItem> items,
    int total,
    ReceiptPaymentMethodEnum paymentMethod,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReceipt.copyWith(...)` or call `instanceOfReceipt.copyWith.fieldName(value)` for a single field.
class _$ReceiptCWProxyImpl implements _$ReceiptCWProxy {
  const _$ReceiptCWProxyImpl(this._value);

  final Receipt _value;

  @override
  Receipt bookingId(String bookingId) => call(bookingId: bookingId);

  @override
  Receipt number(String number) => call(number: number);

  @override
  Receipt completedAt(DateTime completedAt) => call(completedAt: completedAt);

  @override
  Receipt serviceName(LocalizedText serviceName) =>
      call(serviceName: serviceName);

  @override
  Receipt providerName(String providerName) => call(providerName: providerName);

  @override
  Receipt customerName(String customerName) => call(customerName: customerName);

  @override
  Receipt area(String? area) => call(area: area);

  @override
  Receipt items(List<BookingItem> items) => call(items: items);

  @override
  Receipt total(int total) => call(total: total);

  @override
  Receipt paymentMethod(ReceiptPaymentMethodEnum paymentMethod) =>
      call(paymentMethod: paymentMethod);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Receipt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Receipt(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Receipt call({
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? completedAt = const $CopyWithPlaceholder(),
    Object? serviceName = const $CopyWithPlaceholder(),
    Object? providerName = const $CopyWithPlaceholder(),
    Object? customerName = const $CopyWithPlaceholder(),
    Object? area = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? paymentMethod = const $CopyWithPlaceholder(),
  }) {
    return Receipt(
      bookingId: bookingId == const $CopyWithPlaceholder() || bookingId == null
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String,
      number: number == const $CopyWithPlaceholder() || number == null
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as String,
      completedAt:
          completedAt == const $CopyWithPlaceholder() || completedAt == null
          ? _value.completedAt
          // ignore: cast_nullable_to_non_nullable
          : completedAt as DateTime,
      serviceName:
          serviceName == const $CopyWithPlaceholder() || serviceName == null
          ? _value.serviceName
          // ignore: cast_nullable_to_non_nullable
          : serviceName as LocalizedText,
      providerName:
          providerName == const $CopyWithPlaceholder() || providerName == null
          ? _value.providerName
          // ignore: cast_nullable_to_non_nullable
          : providerName as String,
      customerName:
          customerName == const $CopyWithPlaceholder() || customerName == null
          ? _value.customerName
          // ignore: cast_nullable_to_non_nullable
          : customerName as String,
      area: area == const $CopyWithPlaceholder()
          ? _value.area
          // ignore: cast_nullable_to_non_nullable
          : area as String?,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItem>,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      paymentMethod:
          paymentMethod == const $CopyWithPlaceholder() || paymentMethod == null
          ? _value.paymentMethod
          // ignore: cast_nullable_to_non_nullable
          : paymentMethod as ReceiptPaymentMethodEnum,
    );
  }
}

extension $ReceiptCopyWith on Receipt {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReceipt.copyWith(...)` or `instanceOfReceipt.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReceiptCWProxy get copyWith => _$ReceiptCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Receipt _$ReceiptFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Receipt', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'bookingId',
          'number',
          'completedAt',
          'serviceName',
          'providerName',
          'customerName',
          'items',
          'total',
          'paymentMethod',
        ],
      );
      final val = Receipt(
        bookingId: $checkedConvert('bookingId', (v) => v as String),
        number: $checkedConvert('number', (v) => v as String),
        completedAt: $checkedConvert(
          'completedAt',
          (v) => DateTime.parse(v as String),
        ),
        serviceName: $checkedConvert(
          'serviceName',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        providerName: $checkedConvert('providerName', (v) => v as String),
        customerName: $checkedConvert('customerName', (v) => v as String),
        area: $checkedConvert('area', (v) => v as String?),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        paymentMethod: $checkedConvert(
          'paymentMethod',
          (v) => $enumDecode(_$ReceiptPaymentMethodEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReceiptToJson(Receipt instance) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'number': instance.number,
  'completedAt': instance.completedAt.toIso8601String(),
  'serviceName': instance.serviceName.toJson(),
  'providerName': instance.providerName,
  'customerName': instance.customerName,
  'area': ?instance.area,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'paymentMethod': _$ReceiptPaymentMethodEnumEnumMap[instance.paymentMethod]!,
};

const _$ReceiptPaymentMethodEnumEnumMap = {
  ReceiptPaymentMethodEnum.cash: 'cash',
};
