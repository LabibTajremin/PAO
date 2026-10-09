// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CategoryCWProxy {
  Category id(String id);

  Category name(LocalizedText name);

  Category iconKey(String iconKey);

  Category sortOrder(int sortOrder);

  Category published(bool published);

  Category services(List<Service> services);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Category(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Category(...).copyWith(id: 12, name: "My name")
  /// ```
  Category call({
    String id,
    LocalizedText name,
    String iconKey,
    int sortOrder,
    bool published,
    List<Service> services,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCategory.copyWith(...)` or call `instanceOfCategory.copyWith.fieldName(value)` for a single field.
class _$CategoryCWProxyImpl implements _$CategoryCWProxy {
  const _$CategoryCWProxyImpl(this._value);

  final Category _value;

  @override
  Category id(String id) => call(id: id);

  @override
  Category name(LocalizedText name) => call(name: name);

  @override
  Category iconKey(String iconKey) => call(iconKey: iconKey);

  @override
  Category sortOrder(int sortOrder) => call(sortOrder: sortOrder);

  @override
  Category published(bool published) => call(published: published);

  @override
  Category services(List<Service> services) => call(services: services);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Category(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Category(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Category call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? iconKey = const $CopyWithPlaceholder(),
    Object? sortOrder = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
    Object? services = const $CopyWithPlaceholder(),
  }) {
    return Category(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as LocalizedText,
      iconKey: iconKey == const $CopyWithPlaceholder() || iconKey == null
          ? _value.iconKey
          // ignore: cast_nullable_to_non_nullable
          : iconKey as String,
      sortOrder: sortOrder == const $CopyWithPlaceholder() || sortOrder == null
          ? _value.sortOrder
          // ignore: cast_nullable_to_non_nullable
          : sortOrder as int,
      published: published == const $CopyWithPlaceholder() || published == null
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool,
      services: services == const $CopyWithPlaceholder() || services == null
          ? _value.services
          // ignore: cast_nullable_to_non_nullable
          : services as List<Service>,
    );
  }
}

extension $CategoryCopyWith on Category {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCategory.copyWith(...)` or `instanceOfCategory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CategoryCWProxy get copyWith => _$CategoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Category', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'iconKey',
          'sortOrder',
          'published',
          'services',
        ],
      );
      final val = Category(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert(
          'name',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        iconKey: $checkedConvert('iconKey', (v) => v as String),
        sortOrder: $checkedConvert('sortOrder', (v) => (v as num).toInt()),
        published: $checkedConvert('published', (v) => v as bool),
        services: $checkedConvert(
          'services',
          (v) => (v as List<dynamic>)
              .map((e) => Service.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name.toJson(),
  'iconKey': instance.iconKey,
  'sortOrder': instance.sortOrder,
  'published': instance.published,
  'services': instance.services.map((e) => e.toJson()).toList(),
};
