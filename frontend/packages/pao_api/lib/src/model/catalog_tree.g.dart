// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_tree.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CatalogTreeCWProxy {
  CatalogTree version(int version);

  CatalogTree categories(List<Category> categories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogTree(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogTree(...).copyWith(id: 12, name: "My name")
  /// ```
  CatalogTree call({int version, List<Category> categories});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCatalogTree.copyWith(...)` or call `instanceOfCatalogTree.copyWith.fieldName(value)` for a single field.
class _$CatalogTreeCWProxyImpl implements _$CatalogTreeCWProxy {
  const _$CatalogTreeCWProxyImpl(this._value);

  final CatalogTree _value;

  @override
  CatalogTree version(int version) => call(version: version);

  @override
  CatalogTree categories(List<Category> categories) =>
      call(categories: categories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogTree(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogTree(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CatalogTree call({
    Object? version = const $CopyWithPlaceholder(),
    Object? categories = const $CopyWithPlaceholder(),
  }) {
    return CatalogTree(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      categories:
          categories == const $CopyWithPlaceholder() || categories == null
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<Category>,
    );
  }
}

extension $CatalogTreeCopyWith on CatalogTree {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCatalogTree.copyWith(...)` or `instanceOfCatalogTree.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CatalogTreeCWProxy get copyWith => _$CatalogTreeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogTree _$CatalogTreeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CatalogTree', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version', 'categories']);
      final val = CatalogTree(
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        categories: $checkedConvert(
          'categories',
          (v) => (v as List<dynamic>)
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CatalogTreeToJson(CatalogTree instance) =>
    <String, dynamic>{
      'version': instance.version,
      'categories': instance.categories.map((e) => e.toJson()).toList(),
    };
