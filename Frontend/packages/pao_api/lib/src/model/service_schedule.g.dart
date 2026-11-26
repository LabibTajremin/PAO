// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_schedule.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServiceScheduleCWProxy {
  ServiceSchedule patterns(Set<DeliveryPattern> patterns);

  ServiceSchedule windows(List<DeliveryWindow> windows);

  ServiceSchedule leadHours(int leadHours);

  ServiceSchedule cutoff(String cutoff);

  ServiceSchedule unit(QuantityUnit unit);

  ServiceSchedule minQuantity(int minQuantity);

  ServiceSchedule maxQuantity(int maxQuantity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceSchedule(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceSchedule(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceSchedule call({
    Set<DeliveryPattern> patterns,
    List<DeliveryWindow> windows,
    int leadHours,
    String cutoff,
    QuantityUnit unit,
    int minQuantity,
    int maxQuantity,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServiceSchedule.copyWith(...)` or call `instanceOfServiceSchedule.copyWith.fieldName(value)` for a single field.
class _$ServiceScheduleCWProxyImpl implements _$ServiceScheduleCWProxy {
  const _$ServiceScheduleCWProxyImpl(this._value);

  final ServiceSchedule _value;

  @override
  ServiceSchedule patterns(Set<DeliveryPattern> patterns) =>
      call(patterns: patterns);

  @override
  ServiceSchedule windows(List<DeliveryWindow> windows) =>
      call(windows: windows);

  @override
  ServiceSchedule leadHours(int leadHours) => call(leadHours: leadHours);

  @override
  ServiceSchedule cutoff(String cutoff) => call(cutoff: cutoff);

  @override
  ServiceSchedule unit(QuantityUnit unit) => call(unit: unit);

  @override
  ServiceSchedule minQuantity(int minQuantity) =>
      call(minQuantity: minQuantity);

  @override
  ServiceSchedule maxQuantity(int maxQuantity) =>
      call(maxQuantity: maxQuantity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServiceSchedule(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceSchedule(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServiceSchedule call({
    Object? patterns = const $CopyWithPlaceholder(),
    Object? windows = const $CopyWithPlaceholder(),
    Object? leadHours = const $CopyWithPlaceholder(),
    Object? cutoff = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? minQuantity = const $CopyWithPlaceholder(),
    Object? maxQuantity = const $CopyWithPlaceholder(),
  }) {
    return ServiceSchedule(
      patterns: patterns == const $CopyWithPlaceholder() || patterns == null
          ? _value.patterns
          // ignore: cast_nullable_to_non_nullable
          : patterns as Set<DeliveryPattern>,
      windows: windows == const $CopyWithPlaceholder() || windows == null
          ? _value.windows
          // ignore: cast_nullable_to_non_nullable
          : windows as List<DeliveryWindow>,
      leadHours: leadHours == const $CopyWithPlaceholder() || leadHours == null
          ? _value.leadHours
          // ignore: cast_nullable_to_non_nullable
          : leadHours as int,
      cutoff: cutoff == const $CopyWithPlaceholder() || cutoff == null
          ? _value.cutoff
          // ignore: cast_nullable_to_non_nullable
          : cutoff as String,
      unit: unit == const $CopyWithPlaceholder() || unit == null
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as QuantityUnit,
      minQuantity:
          minQuantity == const $CopyWithPlaceholder() || minQuantity == null
          ? _value.minQuantity
          // ignore: cast_nullable_to_non_nullable
          : minQuantity as int,
      maxQuantity:
          maxQuantity == const $CopyWithPlaceholder() || maxQuantity == null
          ? _value.maxQuantity
          // ignore: cast_nullable_to_non_nullable
          : maxQuantity as int,
    );
  }
}

extension $ServiceScheduleCopyWith on ServiceSchedule {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServiceSchedule.copyWith(...)` or `instanceOfServiceSchedule.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceScheduleCWProxy get copyWith => _$ServiceScheduleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceSchedule _$ServiceScheduleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ServiceSchedule', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'patterns',
          'windows',
          'leadHours',
          'cutoff',
          'unit',
          'minQuantity',
          'maxQuantity',
        ],
      );
      final val = ServiceSchedule(
        patterns: $checkedConvert(
          'patterns',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$DeliveryPatternEnumMap, e))
              .toSet(),
        ),
        windows: $checkedConvert(
          'windows',
          (v) => (v as List<dynamic>)
              .map((e) => DeliveryWindow.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        leadHours: $checkedConvert('leadHours', (v) => (v as num).toInt()),
        cutoff: $checkedConvert('cutoff', (v) => v as String),
        unit: $checkedConvert(
          'unit',
          (v) => $enumDecode(_$QuantityUnitEnumMap, v),
        ),
        minQuantity: $checkedConvert('minQuantity', (v) => (v as num).toInt()),
        maxQuantity: $checkedConvert('maxQuantity', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ServiceScheduleToJson(ServiceSchedule instance) =>
    <String, dynamic>{
      'patterns': instance.patterns
          .map((e) => _$DeliveryPatternEnumMap[e]!)
          .toList(),
      'windows': instance.windows.map((e) => e.toJson()).toList(),
      'leadHours': instance.leadHours,
      'cutoff': instance.cutoff,
      'unit': _$QuantityUnitEnumMap[instance.unit]!,
      'minQuantity': instance.minQuantity,
      'maxQuantity': instance.maxQuantity,
    };

const _$DeliveryPatternEnumMap = {
  DeliveryPattern.once: 'once',
  DeliveryPattern.daily: 'daily',
  DeliveryPattern.weekdays: 'weekdays',
  DeliveryPattern.weekly: 'weekly',
  DeliveryPattern.monthly: 'monthly',
};

const _$QuantityUnitEnumMap = {
  QuantityUnit.meals: 'meals',
  QuantityUnit.guests: 'guests',
  QuantityUnit.package: 'package',
};
