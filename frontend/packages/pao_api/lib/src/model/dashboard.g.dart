// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DashboardCWProxy {
  Dashboard providersByStatus(Map<String, int> providersByStatus);

  Dashboard providersByLevel(Map<String, int> providersByLevel);

  Dashboard bookingsPerDay(List<DashboardBookingsPerDayInner> bookingsPerDay);

  Dashboard completionRate(double completionRate);

  Dashboard openComplaints(int openComplaints);

  Dashboard pendingVerifications(int pendingVerifications);

  Dashboard generatedAt(DateTime generatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Dashboard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Dashboard(...).copyWith(id: 12, name: "My name")
  /// ```
  Dashboard call({
    Map<String, int> providersByStatus,
    Map<String, int> providersByLevel,
    List<DashboardBookingsPerDayInner> bookingsPerDay,
    double completionRate,
    int openComplaints,
    int pendingVerifications,
    DateTime generatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDashboard.copyWith(...)` or call `instanceOfDashboard.copyWith.fieldName(value)` for a single field.
class _$DashboardCWProxyImpl implements _$DashboardCWProxy {
  const _$DashboardCWProxyImpl(this._value);

  final Dashboard _value;

  @override
  Dashboard providersByStatus(Map<String, int> providersByStatus) =>
      call(providersByStatus: providersByStatus);

  @override
  Dashboard providersByLevel(Map<String, int> providersByLevel) =>
      call(providersByLevel: providersByLevel);

  @override
  Dashboard bookingsPerDay(List<DashboardBookingsPerDayInner> bookingsPerDay) =>
      call(bookingsPerDay: bookingsPerDay);

  @override
  Dashboard completionRate(double completionRate) =>
      call(completionRate: completionRate);

  @override
  Dashboard openComplaints(int openComplaints) =>
      call(openComplaints: openComplaints);

  @override
  Dashboard pendingVerifications(int pendingVerifications) =>
      call(pendingVerifications: pendingVerifications);

  @override
  Dashboard generatedAt(DateTime generatedAt) => call(generatedAt: generatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Dashboard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Dashboard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Dashboard call({
    Object? providersByStatus = const $CopyWithPlaceholder(),
    Object? providersByLevel = const $CopyWithPlaceholder(),
    Object? bookingsPerDay = const $CopyWithPlaceholder(),
    Object? completionRate = const $CopyWithPlaceholder(),
    Object? openComplaints = const $CopyWithPlaceholder(),
    Object? pendingVerifications = const $CopyWithPlaceholder(),
    Object? generatedAt = const $CopyWithPlaceholder(),
  }) {
    return Dashboard(
      providersByStatus:
          providersByStatus == const $CopyWithPlaceholder() ||
              providersByStatus == null
          ? _value.providersByStatus
          // ignore: cast_nullable_to_non_nullable
          : providersByStatus as Map<String, int>,
      providersByLevel:
          providersByLevel == const $CopyWithPlaceholder() ||
              providersByLevel == null
          ? _value.providersByLevel
          // ignore: cast_nullable_to_non_nullable
          : providersByLevel as Map<String, int>,
      bookingsPerDay:
          bookingsPerDay == const $CopyWithPlaceholder() ||
              bookingsPerDay == null
          ? _value.bookingsPerDay
          // ignore: cast_nullable_to_non_nullable
          : bookingsPerDay as List<DashboardBookingsPerDayInner>,
      completionRate:
          completionRate == const $CopyWithPlaceholder() ||
              completionRate == null
          ? _value.completionRate
          // ignore: cast_nullable_to_non_nullable
          : completionRate as double,
      openComplaints:
          openComplaints == const $CopyWithPlaceholder() ||
              openComplaints == null
          ? _value.openComplaints
          // ignore: cast_nullable_to_non_nullable
          : openComplaints as int,
      pendingVerifications:
          pendingVerifications == const $CopyWithPlaceholder() ||
              pendingVerifications == null
          ? _value.pendingVerifications
          // ignore: cast_nullable_to_non_nullable
          : pendingVerifications as int,
      generatedAt:
          generatedAt == const $CopyWithPlaceholder() || generatedAt == null
          ? _value.generatedAt
          // ignore: cast_nullable_to_non_nullable
          : generatedAt as DateTime,
    );
  }
}

extension $DashboardCopyWith on Dashboard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDashboard.copyWith(...)` or `instanceOfDashboard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DashboardCWProxy get copyWith => _$DashboardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dashboard _$DashboardFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Dashboard', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'providersByStatus',
          'providersByLevel',
          'bookingsPerDay',
          'completionRate',
          'openComplaints',
          'pendingVerifications',
          'generatedAt',
        ],
      );
      final val = Dashboard(
        providersByStatus: $checkedConvert(
          'providersByStatus',
          (v) => Map<String, int>.from(v as Map),
        ),
        providersByLevel: $checkedConvert(
          'providersByLevel',
          (v) => Map<String, int>.from(v as Map),
        ),
        bookingsPerDay: $checkedConvert(
          'bookingsPerDay',
          (v) => (v as List<dynamic>)
              .map(
                (e) => DashboardBookingsPerDayInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        completionRate: $checkedConvert(
          'completionRate',
          (v) => (v as num).toDouble(),
        ),
        openComplaints: $checkedConvert(
          'openComplaints',
          (v) => (v as num).toInt(),
        ),
        pendingVerifications: $checkedConvert(
          'pendingVerifications',
          (v) => (v as num).toInt(),
        ),
        generatedAt: $checkedConvert(
          'generatedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DashboardToJson(Dashboard instance) => <String, dynamic>{
  'providersByStatus': instance.providersByStatus,
  'providersByLevel': instance.providersByLevel,
  'bookingsPerDay': instance.bookingsPerDay.map((e) => e.toJson()).toList(),
  'completionRate': instance.completionRate,
  'openComplaints': instance.openComplaints,
  'pendingVerifications': instance.pendingVerifications,
  'generatedAt': instance.generatedAt.toIso8601String(),
};
