// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'icon_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IconLinkCWProxy {
  IconLink url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IconLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IconLink(...).copyWith(id: 12, name: "My name")
  /// ```
  IconLink call({String url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIconLink.copyWith(...)` or call `instanceOfIconLink.copyWith.fieldName(value)` for a single field.
class _$IconLinkCWProxyImpl implements _$IconLinkCWProxy {
  const _$IconLinkCWProxyImpl(this._value);

  final IconLink _value;

  @override
  IconLink url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IconLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IconLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IconLink call({Object? url = const $CopyWithPlaceholder()}) {
    return IconLink(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $IconLinkCopyWith on IconLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIconLink.copyWith(...)` or `instanceOfIconLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IconLinkCWProxy get copyWith => _$IconLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IconLink _$IconLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IconLink', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url']);
      final val = IconLink(url: $checkedConvert('url', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$IconLinkToJson(IconLink instance) => <String, dynamic>{
  'url': instance.url,
};
