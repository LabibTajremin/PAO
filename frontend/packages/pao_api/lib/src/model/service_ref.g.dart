// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServiceRefCWProxy {
  ServiceRef id(String id);

  ServiceRef name(LocalizedText name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceRef(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceRef call({String id, LocalizedText name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServiceRef.copyWith(...)` or call `instanceOfServiceRef.copyWith.fieldName(value)` for a single field.
class _$ServiceRefCWProxyImpl implements _$ServiceRefCWProxy {
  const _$ServiceRefCWProxyImpl(this._value);

  final ServiceRef _value;

  @override
  ServiceRef id(String id) => call(id: id);

  @override
  ServiceRef name(LocalizedText name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceRef(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceRef(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServiceRef call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return ServiceRef(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as LocalizedText,
    );
  }
}

extension $ServiceRefCopyWith on ServiceRef {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServiceRef.copyWith(...)` or `instanceOfServiceRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceRefCWProxy get copyWith => _$ServiceRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceRef _$ServiceRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ServiceRef', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name']);
      final val = ServiceRef(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert(
          'name',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ServiceRefToJson(ServiceRef instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name.toJson()};
