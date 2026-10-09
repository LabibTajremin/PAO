// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_bookings_per_day_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DashboardBookingsPerDayInnerCWProxy {
  DashboardBookingsPerDayInner date(DateTime date);

  DashboardBookingsPerDayInner total(int total);

  DashboardBookingsPerDayInner completed(int completed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DashboardBookingsPerDayInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DashboardBookingsPerDayInner(...).copyWith(id: 12, name: "My name")
  /// ```
  DashboardBookingsPerDayInner call({DateTime date, int total, int completed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDashboardBookingsPerDayInner.copyWith(...)` or call `instanceOfDashboardBookingsPerDayInner.copyWith.fieldName(value)` for a single field.
class _$DashboardBookingsPerDayInnerCWProxyImpl
    implements _$DashboardBookingsPerDayInnerCWProxy {
  const _$DashboardBookingsPerDayInnerCWProxyImpl(this._value);

  final DashboardBookingsPerDayInner _value;

  @override
  DashboardBookingsPerDayInner date(DateTime date) => call(date: date);

  @override
  DashboardBookingsPerDayInner total(int total) => call(total: total);

  @override
  DashboardBookingsPerDayInner completed(int completed) =>
      call(completed: completed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DashboardBookingsPerDayInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DashboardBookingsPerDayInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DashboardBookingsPerDayInner call({
    Object? date = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? completed = const $CopyWithPlaceholder(),
  }) {
    return DashboardBookingsPerDayInner(
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as DateTime,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      completed: completed == const $CopyWithPlaceholder() || completed == null
          ? _value.completed
          // ignore: cast_nullable_to_non_nullable
          : completed as int,
    );
  }
}

extension $DashboardBookingsPerDayInnerCopyWith
    on DashboardBookingsPerDayInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDashboardBookingsPerDayInner.copyWith(...)` or `instanceOfDashboardBookingsPerDayInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DashboardBookingsPerDayInnerCWProxy get copyWith =>
      _$DashboardBookingsPerDayInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardBookingsPerDayInner _$DashboardBookingsPerDayInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DashboardBookingsPerDayInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['date', 'total', 'completed']);
  final val = DashboardBookingsPerDayInner(
    date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
    total: $checkedConvert('total', (v) => (v as num).toInt()),
    completed: $checkedConvert('completed', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$DashboardBookingsPerDayInnerToJson(
  DashboardBookingsPerDayInner instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'total': instance.total,
  'completed': instance.completed,
};
