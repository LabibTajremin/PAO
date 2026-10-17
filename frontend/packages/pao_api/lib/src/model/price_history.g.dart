// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PriceHistoryCWProxy {
  PriceHistory items(List<PriceVersion> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceHistory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceHistory(...).copyWith(id: 12, name: "My name")
  /// ```
  PriceHistory call({List<PriceVersion> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPriceHistory.copyWith(...)` or call `instanceOfPriceHistory.copyWith.fieldName(value)` for a single field.
class _$PriceHistoryCWProxyImpl implements _$PriceHistoryCWProxy {
  const _$PriceHistoryCWProxyImpl(this._value);

  final PriceHistory _value;

  @override
  PriceHistory items(List<PriceVersion> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PriceHistory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PriceHistory(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PriceHistory call({Object? items = const $CopyWithPlaceholder()}) {
    return PriceHistory(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PriceVersion>,
    );
  }
}

extension $PriceHistoryCopyWith on PriceHistory {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPriceHistory.copyWith(...)` or `instanceOfPriceHistory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PriceHistoryCWProxy get copyWith => _$PriceHistoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceHistory _$PriceHistoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PriceHistory', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PriceHistory(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PriceVersion.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PriceHistoryToJson(PriceHistory instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
