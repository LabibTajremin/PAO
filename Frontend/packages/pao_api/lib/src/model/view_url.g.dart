// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_url.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ViewUrlCWProxy {
  ViewUrl url(String url);

  ViewUrl expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ViewUrl(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ViewUrl(...).copyWith(id: 12, name: "My name")
  /// ```
  ViewUrl call({String url, DateTime expiresAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfViewUrl.copyWith(...)` or call `instanceOfViewUrl.copyWith.fieldName(value)` for a single field.
class _$ViewUrlCWProxyImpl implements _$ViewUrlCWProxy {
  const _$ViewUrlCWProxyImpl(this._value);

  final ViewUrl _value;

  @override
  ViewUrl url(String url) => call(url: url);

  @override
  ViewUrl expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ViewUrl(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ViewUrl(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ViewUrl call({
    Object? url = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return ViewUrl(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $ViewUrlCopyWith on ViewUrl {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfViewUrl.copyWith(...)` or `instanceOfViewUrl.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ViewUrlCWProxy get copyWith => _$ViewUrlCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ViewUrl _$ViewUrlFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ViewUrl', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url', 'expiresAt']);
      final val = ViewUrl(
        url: $checkedConvert('url', (v) => v as String),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ViewUrlToJson(ViewUrl instance) => <String, dynamic>{
  'url': instance.url,
  'expiresAt': instance.expiresAt.toIso8601String(),
};
