// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extras_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExtrasInputCWProxy {
  ExtrasInput items(List<BookingItemInput> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExtrasInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExtrasInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ExtrasInput call({List<BookingItemInput> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfExtrasInput.copyWith(...)` or call `instanceOfExtrasInput.copyWith.fieldName(value)` for a single field.
class _$ExtrasInputCWProxyImpl implements _$ExtrasInputCWProxy {
  const _$ExtrasInputCWProxyImpl(this._value);

  final ExtrasInput _value;

  @override
  ExtrasInput items(List<BookingItemInput> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExtrasInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExtrasInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ExtrasInput call({Object? items = const $CopyWithPlaceholder()}) {
    return ExtrasInput(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItemInput>,
    );
  }
}

extension $ExtrasInputCopyWith on ExtrasInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfExtrasInput.copyWith(...)` or `instanceOfExtrasInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExtrasInputCWProxy get copyWith => _$ExtrasInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtrasInput _$ExtrasInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExtrasInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ExtrasInput(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingItemInput.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExtrasInputToJson(ExtrasInput instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
