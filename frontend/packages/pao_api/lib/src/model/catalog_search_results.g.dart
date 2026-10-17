// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_search_results.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CatalogSearchResultsCWProxy {
  CatalogSearchResults services(List<Service> services);

  CatalogSearchResults subServices(List<SubService> subServices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogSearchResults(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogSearchResults(...).copyWith(id: 12, name: "My name")
  /// ```
  CatalogSearchResults call({
    List<Service> services,
    List<SubService> subServices,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCatalogSearchResults.copyWith(...)` or call `instanceOfCatalogSearchResults.copyWith.fieldName(value)` for a single field.
class _$CatalogSearchResultsCWProxyImpl
    implements _$CatalogSearchResultsCWProxy {
  const _$CatalogSearchResultsCWProxyImpl(this._value);

  final CatalogSearchResults _value;

  @override
  CatalogSearchResults services(List<Service> services) =>
      call(services: services);

  @override
  CatalogSearchResults subServices(List<SubService> subServices) =>
      call(subServices: subServices);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogSearchResults(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogSearchResults(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CatalogSearchResults call({
    Object? services = const $CopyWithPlaceholder(),
    Object? subServices = const $CopyWithPlaceholder(),
  }) {
    return CatalogSearchResults(
      services: services == const $CopyWithPlaceholder() || services == null
          ? _value.services
          // ignore: cast_nullable_to_non_nullable
          : services as List<Service>,
      subServices:
          subServices == const $CopyWithPlaceholder() || subServices == null
          ? _value.subServices
          // ignore: cast_nullable_to_non_nullable
          : subServices as List<SubService>,
    );
  }
}

extension $CatalogSearchResultsCopyWith on CatalogSearchResults {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCatalogSearchResults.copyWith(...)` or `instanceOfCatalogSearchResults.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CatalogSearchResultsCWProxy get copyWith =>
      _$CatalogSearchResultsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogSearchResults _$CatalogSearchResultsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CatalogSearchResults', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['services', 'subServices']);
  final val = CatalogSearchResults(
    services: $checkedConvert(
      'services',
      (v) => (v as List<dynamic>)
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    subServices: $checkedConvert(
      'subServices',
      (v) => (v as List<dynamic>)
          .map((e) => SubService.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$CatalogSearchResultsToJson(
  CatalogSearchResults instance,
) => <String, dynamic>{
  'services': instance.services.map((e) => e.toJson()).toList(),
  'subServices': instance.subServices.map((e) => e.toJson()).toList(),
};
