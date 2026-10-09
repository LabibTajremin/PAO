// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CategoryInputCWProxy {
  CategoryInput name(LocalizedText name);

  CategoryInput iconKey(String iconKey);

  CategoryInput sortOrder(int? sortOrder);

  CategoryInput published(bool? published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CategoryInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CategoryInput(...).copyWith(id: 12, name: "My name")
  /// ```
  CategoryInput call({
    LocalizedText name,
    String iconKey,
    int? sortOrder,
    bool? published,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCategoryInput.copyWith(...)` or call `instanceOfCategoryInput.copyWith.fieldName(value)` for a single field.
class _$CategoryInputCWProxyImpl implements _$CategoryInputCWProxy {
  const _$CategoryInputCWProxyImpl(this._value);

  final CategoryInput _value;

  @override
  CategoryInput name(LocalizedText name) => call(name: name);

  @override
  CategoryInput iconKey(String iconKey) => call(iconKey: iconKey);

  @override
  CategoryInput sortOrder(int? sortOrder) => call(sortOrder: sortOrder);

  @override
  CategoryInput published(bool? published) => call(published: published);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CategoryInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CategoryInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CategoryInput call({
    Object? name = const $CopyWithPlaceholder(),
    Object? iconKey = const $CopyWithPlaceholder(),
    Object? sortOrder = const $CopyWithPlaceholder(),
    Object? published = const $CopyWithPlaceholder(),
  }) {
    return CategoryInput(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as LocalizedText,
      iconKey: iconKey == const $CopyWithPlaceholder() || iconKey == null
          ? _value.iconKey
          // ignore: cast_nullable_to_non_nullable
          : iconKey as String,
      sortOrder: sortOrder == const $CopyWithPlaceholder()
          ? _value.sortOrder
          // ignore: cast_nullable_to_non_nullable
          : sortOrder as int?,
      published: published == const $CopyWithPlaceholder()
          ? _value.published
          // ignore: cast_nullable_to_non_nullable
          : published as bool?,
    );
  }
}

extension $CategoryInputCopyWith on CategoryInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCategoryInput.copyWith(...)` or `instanceOfCategoryInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CategoryInputCWProxy get copyWith => _$CategoryInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryInput _$CategoryInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CategoryInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'iconKey']);
      final val = CategoryInput(
        name: $checkedConvert(
          'name',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        iconKey: $checkedConvert('iconKey', (v) => v as String),
        sortOrder: $checkedConvert('sortOrder', (v) => (v as num?)?.toInt()),
        published: $checkedConvert('published', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$CategoryInputToJson(CategoryInput instance) =>
    <String, dynamic>{
      'name': instance.name.toJson(),
      'iconKey': instance.iconKey,
      'sortOrder': ?instance.sortOrder,
      'published': ?instance.published,
    };
