// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_area_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServiceAreaInputCWProxy {
  ServiceAreaInput homeBase(Point homeBase);

  ServiceAreaInput workingRadiusM(int workingRadiusM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceAreaInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceAreaInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceAreaInput call({Point homeBase, int workingRadiusM});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServiceAreaInput.copyWith(...)` or call `instanceOfServiceAreaInput.copyWith.fieldName(value)` for a single field.
class _$ServiceAreaInputCWProxyImpl implements _$ServiceAreaInputCWProxy {
  const _$ServiceAreaInputCWProxyImpl(this._value);

  final ServiceAreaInput _value;

  @override
  ServiceAreaInput homeBase(Point homeBase) => call(homeBase: homeBase);

  @override
  ServiceAreaInput workingRadiusM(int workingRadiusM) =>
      call(workingRadiusM: workingRadiusM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceAreaInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceAreaInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServiceAreaInput call({
    Object? homeBase = const $CopyWithPlaceholder(),
    Object? workingRadiusM = const $CopyWithPlaceholder(),
  }) {
    return ServiceAreaInput(
      homeBase: homeBase == const $CopyWithPlaceholder() || homeBase == null
          ? _value.homeBase
          // ignore: cast_nullable_to_non_nullable
          : homeBase as Point,
      workingRadiusM:
          workingRadiusM == const $CopyWithPlaceholder() ||
              workingRadiusM == null
          ? _value.workingRadiusM
          // ignore: cast_nullable_to_non_nullable
          : workingRadiusM as int,
    );
  }
}

extension $ServiceAreaInputCopyWith on ServiceAreaInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServiceAreaInput.copyWith(...)` or `instanceOfServiceAreaInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceAreaInputCWProxy get copyWith => _$ServiceAreaInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAreaInput _$ServiceAreaInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ServiceAreaInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['homeBase', 'workingRadiusM']);
      final val = ServiceAreaInput(
        homeBase: $checkedConvert(
          'homeBase',
          (v) => Point.fromJson(v as Map<String, dynamic>),
        ),
        workingRadiusM: $checkedConvert(
          'workingRadiusM',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ServiceAreaInputToJson(ServiceAreaInput instance) =>
    <String, dynamic>{
      'homeBase': instance.homeBase.toJson(),
      'workingRadiusM': instance.workingRadiusM,
    };
