// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_job.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EarningsJobCWProxy {
  EarningsJob bookingId(String bookingId);

  EarningsJob number(String number);

  EarningsJob completedAt(DateTime completedAt);

  EarningsJob serviceName(LocalizedText serviceName);

  EarningsJob total(int total);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsJob(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsJob(...).copyWith(id: 12, name: "My name")
  /// ```
  EarningsJob call({
    String bookingId,
    String number,
    DateTime completedAt,
    LocalizedText serviceName,
    int total,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEarningsJob.copyWith(...)` or call `instanceOfEarningsJob.copyWith.fieldName(value)` for a single field.
class _$EarningsJobCWProxyImpl implements _$EarningsJobCWProxy {
  const _$EarningsJobCWProxyImpl(this._value);

  final EarningsJob _value;

  @override
  EarningsJob bookingId(String bookingId) => call(bookingId: bookingId);

  @override
  EarningsJob number(String number) => call(number: number);

  @override
  EarningsJob completedAt(DateTime completedAt) =>
      call(completedAt: completedAt);

  @override
  EarningsJob serviceName(LocalizedText serviceName) =>
      call(serviceName: serviceName);

  @override
  EarningsJob total(int total) => call(total: total);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `EarningsJob(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EarningsJob(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EarningsJob call({
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? completedAt = const $CopyWithPlaceholder(),
    Object? serviceName = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
  }) {
    return EarningsJob(
      bookingId: bookingId == const $CopyWithPlaceholder() || bookingId == null
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String,
      number: number == const $CopyWithPlaceholder() || number == null
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as String,
      completedAt:
          completedAt == const $CopyWithPlaceholder() || completedAt == null
          ? _value.completedAt
          // ignore: cast_nullable_to_non_nullable
          : completedAt as DateTime,
      serviceName:
          serviceName == const $CopyWithPlaceholder() || serviceName == null
          ? _value.serviceName
          // ignore: cast_nullable_to_non_nullable
          : serviceName as LocalizedText,
      total: total == const $CopyWithPlaceholder() || total == null
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
    );
  }
}

extension $EarningsJobCopyWith on EarningsJob {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEarningsJob.copyWith(...)` or `instanceOfEarningsJob.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EarningsJobCWProxy get copyWith => _$EarningsJobCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EarningsJob _$EarningsJobFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EarningsJob', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'bookingId',
          'number',
          'completedAt',
          'serviceName',
          'total',
        ],
      );
      final val = EarningsJob(
        bookingId: $checkedConvert('bookingId', (v) => v as String),
        number: $checkedConvert('number', (v) => v as String),
        completedAt: $checkedConvert(
          'completedAt',
          (v) => DateTime.parse(v as String),
        ),
        serviceName: $checkedConvert(
          'serviceName',
          (v) => LocalizedText.fromJson(v as Map<String, dynamic>),
        ),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$EarningsJobToJson(EarningsJob instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'number': instance.number,
      'completedAt': instance.completedAt.toIso8601String(),
      'serviceName': instance.serviceName.toJson(),
      'total': instance.total,
    };
