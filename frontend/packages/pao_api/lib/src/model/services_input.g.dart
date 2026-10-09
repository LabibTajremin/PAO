// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServicesInputCWProxy {
  ServicesInput serviceIds(List<String> serviceIds);

  ServicesInput experienceYears(int experienceYears);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServicesInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServicesInput(...).copyWith(id: 12, name: "My name")
  /// ```
  ServicesInput call({List<String> serviceIds, int experienceYears});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServicesInput.copyWith(...)` or call `instanceOfServicesInput.copyWith.fieldName(value)` for a single field.
class _$ServicesInputCWProxyImpl implements _$ServicesInputCWProxy {
  const _$ServicesInputCWProxyImpl(this._value);

  final ServicesInput _value;

  @override
  ServicesInput serviceIds(List<String> serviceIds) =>
      call(serviceIds: serviceIds);

  @override
  ServicesInput experienceYears(int experienceYears) =>
      call(experienceYears: experienceYears);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServicesInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServicesInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServicesInput call({
    Object? serviceIds = const $CopyWithPlaceholder(),
    Object? experienceYears = const $CopyWithPlaceholder(),
  }) {
    return ServicesInput(
      serviceIds:
          serviceIds == const $CopyWithPlaceholder() || serviceIds == null
          ? _value.serviceIds
          // ignore: cast_nullable_to_non_nullable
          : serviceIds as List<String>,
      experienceYears:
          experienceYears == const $CopyWithPlaceholder() ||
              experienceYears == null
          ? _value.experienceYears
          // ignore: cast_nullable_to_non_nullable
          : experienceYears as int,
    );
  }
}

extension $ServicesInputCopyWith on ServicesInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServicesInput.copyWith(...)` or `instanceOfServicesInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServicesInputCWProxy get copyWith => _$ServicesInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServicesInput _$ServicesInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ServicesInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['serviceIds', 'experienceYears']);
      final val = ServicesInput(
        serviceIds: $checkedConvert(
          'serviceIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        experienceYears: $checkedConvert(
          'experienceYears',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ServicesInputToJson(ServicesInput instance) =>
    <String, dynamic>{
      'serviceIds': instance.serviceIds,
      'experienceYears': instance.experienceYears,
    };
