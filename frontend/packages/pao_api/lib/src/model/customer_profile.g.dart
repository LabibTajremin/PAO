// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerProfileCWProxy {
  CustomerProfile id(String id);

  CustomerProfile name(String name);

  CustomerProfile phone(String? phone);

  CustomerProfile photoUrl(String? photoUrl);

  CustomerProfile language(Language language);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomerProfile call({
    String id,
    String name,
    String? phone,
    String? photoUrl,
    Language language,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomerProfile.copyWith(...)` or call `instanceOfCustomerProfile.copyWith.fieldName(value)` for a single field.
class _$CustomerProfileCWProxyImpl implements _$CustomerProfileCWProxy {
  const _$CustomerProfileCWProxyImpl(this._value);

  final CustomerProfile _value;

  @override
  CustomerProfile id(String id) => call(id: id);

  @override
  CustomerProfile name(String name) => call(name: name);

  @override
  CustomerProfile phone(String? phone) => call(phone: phone);

  @override
  CustomerProfile photoUrl(String? photoUrl) => call(photoUrl: photoUrl);

  @override
  CustomerProfile language(Language language) => call(language: language);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CustomerProfile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomerProfile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomerProfile call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? language = const $CopyWithPlaceholder(),
  }) {
    return CustomerProfile(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      photoUrl: photoUrl == const $CopyWithPlaceholder()
          ? _value.photoUrl
          // ignore: cast_nullable_to_non_nullable
          : photoUrl as String?,
      language: language == const $CopyWithPlaceholder() || language == null
          ? _value.language
          // ignore: cast_nullable_to_non_nullable
          : language as Language,
    );
  }
}

extension $CustomerProfileCopyWith on CustomerProfile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomerProfile.copyWith(...)` or `instanceOfCustomerProfile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerProfileCWProxy get copyWith => _$CustomerProfileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerProfile _$CustomerProfileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CustomerProfile', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name', 'language']);
      final val = CustomerProfile(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String?),
        photoUrl: $checkedConvert('photoUrl', (v) => v as String?),
        language: $checkedConvert(
          'language',
          (v) => $enumDecode(_$LanguageEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CustomerProfileToJson(CustomerProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': ?instance.phone,
      'photoUrl': ?instance.photoUrl,
      'language': _$LanguageEnumMap[instance.language]!,
    };

const _$LanguageEnumMap = {Language.en: 'en', Language.bn: 'bn'};
