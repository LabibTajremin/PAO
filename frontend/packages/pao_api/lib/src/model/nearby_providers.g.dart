// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_providers.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NearbyProvidersCWProxy {
  NearbyProviders items(List<ProviderCard> items);

  NearbyProviders priceSummary(PriceSummary priceSummary);

  NearbyProviders nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NearbyProviders(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NearbyProviders(...).copyWith(id: 12, name: "My name")
  /// ```
  NearbyProviders call({
    List<ProviderCard> items,
    PriceSummary priceSummary,
    String? nextCursor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNearbyProviders.copyWith(...)` or call `instanceOfNearbyProviders.copyWith.fieldName(value)` for a single field.
class _$NearbyProvidersCWProxyImpl implements _$NearbyProvidersCWProxy {
  const _$NearbyProvidersCWProxyImpl(this._value);

  final NearbyProviders _value;

  @override
  NearbyProviders items(List<ProviderCard> items) => call(items: items);

  @override
  NearbyProviders priceSummary(PriceSummary priceSummary) =>
      call(priceSummary: priceSummary);

  @override
  NearbyProviders nextCursor(String? nextCursor) =>
      call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NearbyProviders(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NearbyProviders(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  NearbyProviders call({
    Object? items = const $CopyWithPlaceholder(),
    Object? priceSummary = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return NearbyProviders(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ProviderCard>,
      priceSummary:
          priceSummary == const $CopyWithPlaceholder() || priceSummary == null
          ? _value.priceSummary
          // ignore: cast_nullable_to_non_nullable
          : priceSummary as PriceSummary,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $NearbyProvidersCopyWith on NearbyProviders {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNearbyProviders.copyWith(...)` or `instanceOfNearbyProviders.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NearbyProvidersCWProxy get copyWith => _$NearbyProvidersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NearbyProviders _$NearbyProvidersFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NearbyProviders', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'priceSummary']);
      final val = NearbyProviders(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ProviderCard.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        priceSummary: $checkedConvert(
          'priceSummary',
          (v) => PriceSummary.fromJson(v as Map<String, dynamic>),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$NearbyProvidersToJson(NearbyProviders instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'priceSummary': instance.priceSummary.toJson(),
      'nextCursor': ?instance.nextCursor,
    };
