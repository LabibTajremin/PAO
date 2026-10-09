// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localized_text.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalizedTextCWProxy {
  LocalizedText en(String en);

  LocalizedText bn(String bn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalizedText(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalizedText(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalizedText call({String en, String bn});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalizedText.copyWith(...)` or call `instanceOfLocalizedText.copyWith.fieldName(value)` for a single field.
class _$LocalizedTextCWProxyImpl implements _$LocalizedTextCWProxy {
  const _$LocalizedTextCWProxyImpl(this._value);

  final LocalizedText _value;

  @override
  LocalizedText en(String en) => call(en: en);

  @override
  LocalizedText bn(String bn) => call(bn: bn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalizedText(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalizedText(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalizedText call({
    Object? en = const $CopyWithPlaceholder(),
    Object? bn = const $CopyWithPlaceholder(),
  }) {
    return LocalizedText(
      en: en == const $CopyWithPlaceholder() || en == null
          ? _value.en
          // ignore: cast_nullable_to_non_nullable
          : en as String,
      bn: bn == const $CopyWithPlaceholder() || bn == null
          ? _value.bn
          // ignore: cast_nullable_to_non_nullable
          : bn as String,
    );
  }
}

extension $LocalizedTextCopyWith on LocalizedText {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalizedText.copyWith(...)` or `instanceOfLocalizedText.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalizedTextCWProxy get copyWith => _$LocalizedTextCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LocalizedText', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['en', 'bn']);
      final val = LocalizedText(
        en: $checkedConvert('en', (v) => v as String),
        bn: $checkedConvert('bn', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LocalizedTextToJson(LocalizedText instance) =>
    <String, dynamic>{'en': instance.en, 'bn': instance.bn};
