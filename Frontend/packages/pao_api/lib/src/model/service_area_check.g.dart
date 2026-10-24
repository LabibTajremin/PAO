// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_area_check.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServiceAreaCheckCWProxy {
  ServiceAreaCheck covered(bool covered);

  ServiceAreaCheck areaName(String? areaName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceAreaCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceAreaCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceAreaCheck call({bool covered, String? areaName});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServiceAreaCheck.copyWith(...)` or call `instanceOfServiceAreaCheck.copyWith.fieldName(value)` for a single field.
class _$ServiceAreaCheckCWProxyImpl implements _$ServiceAreaCheckCWProxy {
  const _$ServiceAreaCheckCWProxyImpl(this._value);

  final ServiceAreaCheck _value;

  @override
  ServiceAreaCheck covered(bool covered) => call(covered: covered);

  @override
  ServiceAreaCheck areaName(String? areaName) => call(areaName: areaName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceAreaCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceAreaCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServiceAreaCheck call({
    Object? covered = const $CopyWithPlaceholder(),
    Object? areaName = const $CopyWithPlaceholder(),
  }) {
    return ServiceAreaCheck(
      covered: covered == const $CopyWithPlaceholder() || covered == null
          ? _value.covered
          // ignore: cast_nullable_to_non_nullable
          : covered as bool,
      areaName: areaName == const $CopyWithPlaceholder()
          ? _value.areaName
          // ignore: cast_nullable_to_non_nullable
          : areaName as String?,
    );
  }
}

extension $ServiceAreaCheckCopyWith on ServiceAreaCheck {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServiceAreaCheck.copyWith(...)` or `instanceOfServiceAreaCheck.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceAreaCheckCWProxy get copyWith => _$ServiceAreaCheckCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAreaCheck _$ServiceAreaCheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ServiceAreaCheck', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['covered']);
      final val = ServiceAreaCheck(
        covered: $checkedConvert('covered', (v) => v as bool),
        areaName: $checkedConvert('areaName', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ServiceAreaCheckToJson(ServiceAreaCheck instance) =>
    <String, dynamic>{
      'covered': instance.covered,
      'areaName': ?instance.areaName,
    };
