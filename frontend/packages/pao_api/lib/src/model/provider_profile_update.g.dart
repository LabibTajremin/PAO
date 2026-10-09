// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_profile_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderProfileUpdateCWProxy {
  ProviderProfileUpdate bio(String? bio);

  ProviderProfileUpdate photoMediaId(String? photoMediaId);

  ProviderProfileUpdate language(Language language);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderProfileUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderProfileUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderProfileUpdate call({
    String? bio,
    String? photoMediaId,
    Language language,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderProfileUpdate.copyWith(...)` or call `instanceOfProviderProfileUpdate.copyWith.fieldName(value)` for a single field.
class _$ProviderProfileUpdateCWProxyImpl
    implements _$ProviderProfileUpdateCWProxy {
  const _$ProviderProfileUpdateCWProxyImpl(this._value);

  final ProviderProfileUpdate _value;

  @override
  ProviderProfileUpdate bio(String? bio) => call(bio: bio);

  @override
  ProviderProfileUpdate photoMediaId(String? photoMediaId) =>
      call(photoMediaId: photoMediaId);

  @override
  ProviderProfileUpdate language(Language language) => call(language: language);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderProfileUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderProfileUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderProfileUpdate call({
    Object? bio = const $CopyWithPlaceholder(),
    Object? photoMediaId = const $CopyWithPlaceholder(),
    Object? language = const $CopyWithPlaceholder(),
  }) {
    return ProviderProfileUpdate(
      bio: bio == const $CopyWithPlaceholder()
          ? _value.bio
          // ignore: cast_nullable_to_non_nullable
          : bio as String?,
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

extension $ProviderProfileUpdateCopyWith on ProviderProfileUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderProfileUpdate.copyWith(...)` or `instanceOfProviderProfileUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderProfileUpdateCWProxy get copyWith =>
      _$ProviderProfileUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderProfileUpdate _$ProviderProfileUpdateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProviderProfileUpdate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['language']);
  final val = ProviderProfileUpdate(
    bio: $checkedConvert('bio', (v) => v as String?),
    photoMediaId: $checkedConvert('photoMediaId', (v) => v as String?),
    language: $checkedConvert(
      'language',
      (v) => $enumDecode(_$LanguageEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$ProviderProfileUpdateToJson(
  ProviderProfileUpdate instance,
) => <String, dynamic>{
  'bio': ?instance.bio,
  'photoMediaId': ?instance.photoMediaId,
  'language': _$LanguageEnumMap[instance.language]!,
};

const _$LanguageEnumMap = {Language.en: 'en', Language.bn: 'bn'};
