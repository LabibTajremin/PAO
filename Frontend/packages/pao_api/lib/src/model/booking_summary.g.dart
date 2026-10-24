// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingSummaryCWProxy {
  BookingSummary id(String id);

  BookingSummary number(String number);

  BookingSummary status(BookingStatus status);

  BookingSummary serviceName(LocalizedText serviceName);

  BookingSummary counterpartName(String? counterpartName);

  BookingSummary timing(Timing? timing);

  BookingSummary scheduledAt(DateTime? scheduledAt);

  BookingSummary total(int total);

  BookingSummary createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingSummary call({
    String id,
    String number,
    BookingStatus status,
    LocalizedText serviceName,
    String? counterpartName,
    Timing? timing,
    DateTime? scheduledAt,
    int total,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingSummary.copyWith(...)` or call `instanceOfBookingSummary.copyWith.fieldName(value)` for a single field.
class _$BookingSummaryCWProxyImpl implements _$BookingSummaryCWProxy {
  const _$BookingSummaryCWProxyImpl(this._value);

  final BookingSummary _value;

  @override
  BookingSummary id(String id) => call(id: id);

  @override
  BookingSummary number(String number) => call(number: number);

  @override
  BookingSummary status(BookingStatus status) => call(status: status);

  @override
  BookingSummary serviceName(LocalizedText serviceName) =>
      call(serviceName: serviceName);

  @override
  BookingSummary counterpartName(String? counterpartName) =>
      call(counterpartName: counterpartName);

  @override
  BookingSummary timing(Timing? timing) => call(timing: timing);

  @override
  BookingSummary scheduledAt(DateTime? scheduledAt) =>
      call(scheduledAt: scheduledAt);

  @override
  BookingSummary total(int total) => call(total: total);

  @override
  BookingSummary createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? serviceName = const $CopyWithPlaceholder(),
    Object? counterpartName = const $CopyWithPlaceholder(),
    Object? timing = const $CopyWithPlaceholder(),
    Object? scheduledAt = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return BookingSummary(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      number: number == const $CopyWithPlaceholder() || number == null
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as BookingStatus,
      serviceName:
          serviceName == const $CopyWithPlaceholder() || serviceName == null
          ? _value.serviceName
          // ignore: cast_nullable_to_non_nullable
          : serviceName as LocalizedText,
      counterpartName: counterpartName == const $CopyWithPlaceholder()
          ? _value.counterpartName
          // ignore: cast_nullable_to_non_nullable
          : counterpartName as String?,
      timing: timing == const $CopyWithPlaceholder()
          ? _value.timing
          // ignore: cast_nullable_to_non_nullable
          : timing as Timing?,
      scheduledAt: scheduledAt == const $CopyWithPlaceholder()
          ? _value.scheduledAt
          // ignore: cast_nullable_to_non_nullable
          : scheduledAt as DateTime?,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $BookingSummaryCopyWith on BookingSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingSummary.copyWith(...)` or `instanceOfBookingSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingSummaryCWProxy get copyWith => _$BookingSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingSummary _$BookingSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BookingSummary', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'number',
      'status',
      'serviceName',
      'total',
      'createdAt',
    ],
  );
  final val = BookingSummary(
    id: $checkedConvert('id', (v) => v as String),
    number: $checkedConvert('number', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$BookingStatusEnumMap, v),
    ),
    serviceName: $checkedConvert(
      'serviceName',
      (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
    ),
    counterpartName: $checkedConvert('counterpartName', (v) => v as String?),
    timing: $checkedConvert(
      'timing',
      (v) => $enumDecodeNullable(_$TimingEnumMap, v),
    ),
    scheduledAt: $checkedConvert(
      'scheduledAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    total: $checkedConvert('total', (v) => (v as num).toInt()),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$BookingSummaryToJson(BookingSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'status': _$BookingStatusEnumMap[instance.status]!,
      'serviceName': instance.serviceName.toJson(),
      'counterpartName': ?instance.counterpartName,
      'timing': ?_$TimingEnumMap[instance.timing],
      'scheduledAt': ?instance.scheduledAt?.toIso8601String(),
      'total': instance.total,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.requested: 'requested',
  BookingStatus.accepted: 'accepted',
  BookingStatus.onTheWay: 'on_the_way',
  BookingStatus.arrived: 'arrived',
  BookingStatus.inProgress: 'in_progress',
  BookingStatus.completed: 'completed',
  BookingStatus.rejected: 'rejected',
  BookingStatus.timedOut: 'timed_out',
  BookingStatus.cancelled: 'cancelled',
};

const _$TimingEnumMap = {Timing.asap: 'asap', Timing.scheduled: 'scheduled'};
