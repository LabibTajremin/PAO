// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PriceSummaryCWProxy {
  PriceSummary subServiceId(String subServiceId);

  PriceSummary quantity(int quantity);

  PriceSummary unitPrice(int unitPrice);

  PriceSummary total(int total);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  PriceSummary call({
    String subServiceId,
    int quantity,
    int unitPrice,
    int total,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPriceSummary.copyWith(...)` or call `instanceOfPriceSummary.copyWith.fieldName(value)` for a single field.
class _$PriceSummaryCWProxyImpl implements _$PriceSummaryCWProxy {
  const _$PriceSummaryCWProxyImpl(this._value);

  final PriceSummary _value;

  @override
  PriceSummary subServiceId(String subServiceId) =>
      call(subServiceId: subServiceId);

  @override
  PriceSummary quantity(int quantity) => call(quantity: quantity);

  @override
  PriceSummary unitPrice(int unitPrice) => call(unitPrice: unitPrice);

  @override
  PriceSummary total(int total) => call(total: total);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PriceSummary call({
    Object? subServiceId = const $CopyWithPlaceholder(),
    Object? quantity = const $CopyWithPlaceholder(),
    Object? unitPrice = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
  }) {
    return PriceSummary(
      subServiceId:
          subServiceId == const $CopyWithPlaceholder() || subServiceId == null
          ? _value.subServiceId
          // ignore: cast_nullable_to_non_nullable
          : subServiceId as String,
      quantity: quantity == const $CopyWithPlaceholder() || quantity == null
          ? _value.quantity
          // ignore: cast_nullable_to_non_nullable
          : quantity as int,
      unitPrice: unitPrice == const $CopyWithPlaceholder() || unitPrice == null
          ? _value.unitPrice
          // ignore: cast_nullable_to_non_nullable
          : unitPrice as int,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
    );
  }
}

extension $PriceSummaryCopyWith on PriceSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPriceSummary.copyWith(...)` or `instanceOfPriceSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PriceSummaryCWProxy get copyWith => _$PriceSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceSummary _$PriceSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PriceSummary', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['subServiceId', 'quantity', 'unitPrice', 'total'],
      );
      final val = PriceSummary(
        subServiceId: $checkedConvert('subServiceId', (v) => v as String),
        quantity: $checkedConvert('quantity', (v) => (v as num).toInt()),
        unitPrice: $checkedConvert('unitPrice', (v) => (v as num).toInt()),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$PriceSummaryToJson(PriceSummary instance) =>
    <String, dynamic>{
      'subServiceId': instance.subServiceId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'total': instance.total,
    };
