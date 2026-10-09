// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerProfileUpdateCWProxy {
  CustomerProfileUpdate name(String name);

  CustomerProfileUpdate photoMediaId(String? photoMediaId);

  CustomerProfileUpdate language(Language language);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerProfileUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerProfileUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomerProfileUpdate call({
    String name,
    String? photoMediaId,
    Language language,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomerProfileUpdate.copyWith(...)` or call `instanceOfCustomerProfileUpdate.copyWith.fieldName(value)` for a single field.
class _$CustomerProfileUpdateCWProxyImpl
    implements _$CustomerProfileUpdateCWProxy {
  const _$CustomerProfileUpdateCWProxyImpl(this._value);

  final CustomerProfileUpdate _value;

  @override
  CustomerProfileUpdate name(String name) => call(name: name);

  @override
  CustomerProfileUpdate photoMediaId(String? photoMediaId) =>
      call(photoMediaId: photoMediaId);

  @override
  CustomerProfileUpdate language(Language language) => call(language: language);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerProfileUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerProfileUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomerProfileUpdate call({
    Object? name = const $CopyWithPlaceholder(),
    Object? photoMediaId = const $CopyWithPlaceholder(),
    Object? language = const $CopyWithPlaceholder(),
  }) {
    return CustomerProfileUpdate(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      photoMediaId: photoMediaId == const $CopyWithPlaceholder()
          ? _value.photoMediaId
          // ignore: cast_nullable_to_non_nullable
          : photoMediaId as String?,
      language: language == const $CopyWithPlaceholder() || language == null
          ? _value.language
          // ignore: cast_nullable_to_non_nullable
          : language as Language,
    );
  }
}

extension $CustomerProfileUpdateCopyWith on CustomerProfileUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomerProfileUpdate.copyWith(...)` or `instanceOfCustomerProfileUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerProfileUpdateCWProxy get copyWith =>
      _$CustomerProfileUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerProfileUpdate _$CustomerProfileUpdateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CustomerProfileUpdate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'language']);
  final val = CustomerProfileUpdate(
    name: $checkedConvert('name', (v) => v as String),
    photoMediaId: $checkedConvert('photoMediaId', (v) => v as String?),
    language: $checkedConvert(
      'language',
      (v) => $enumDecode(_$LanguageEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$CustomerProfileUpdateToJson(
  CustomerProfileUpdate instance,
) => <String, dynamic>{
  'name': instance.name,
  'photoMediaId': ?instance.photoMediaId,
  'language': _$LanguageEnumMap[instance.language]!,
};

const _$LanguageEnumMap = {Language.en: 'en', Language.bn: 'bn'};
