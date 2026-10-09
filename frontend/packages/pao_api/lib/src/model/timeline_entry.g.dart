// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TimelineEntryCWProxy {
  TimelineEntry status(BookingStatus status);

  TimelineEntry at(DateTime at);

  TimelineEntry actor(TimelineEntryActorEnum actor);

  TimelineEntry reason(String? reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TimelineEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TimelineEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  TimelineEntry call({
    BookingStatus status,
    DateTime at,
    TimelineEntryActorEnum actor,
    String? reason,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTimelineEntry.copyWith(...)` or call `instanceOfTimelineEntry.copyWith.fieldName(value)` for a single field.
class _$TimelineEntryCWProxyImpl implements _$TimelineEntryCWProxy {
  const _$TimelineEntryCWProxyImpl(this._value);

  final TimelineEntry _value;

  @override
  TimelineEntry status(BookingStatus status) => call(status: status);

  @override
  TimelineEntry at(DateTime at) => call(at: at);

  @override
  TimelineEntry actor(TimelineEntryActorEnum actor) => call(actor: actor);

  @override
  TimelineEntry reason(String? reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TimelineEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TimelineEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TimelineEntry call({
    Object? status = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? actor = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return TimelineEntry(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as BookingStatus,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      actor: actor == const $CopyWithPlaceholder() || actor == null
          ? _value.actor
          // ignore: cast_nullable_to_non_nullable
          : actor as TimelineEntryActorEnum,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
    );
  }
}

extension $TimelineEntryCopyWith on TimelineEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTimelineEntry.copyWith(...)` or `instanceOfTimelineEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TimelineEntryCWProxy get copyWith => _$TimelineEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimelineEntry _$TimelineEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TimelineEntry', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status', 'at', 'actor']);
      final val = TimelineEntry(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$BookingStatusEnumMap, v),
        ),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        actor: $checkedConvert(
          'actor',
          (v) => $enumDecode(_$TimelineEntryActorEnumEnumMap, v),
        ),
        reason: $checkedConvert('reason', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TimelineEntryToJson(TimelineEntry instance) =>
    <String, dynamic>{
      'status': _$BookingStatusEnumMap[instance.status]!,
      'at': instance.at.toIso8601String(),
      'actor': _$TimelineEntryActorEnumEnumMap[instance.actor]!,
      'reason': ?instance.reason,
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

const _$TimelineEntryActorEnumEnumMap = {
  TimelineEntryActorEnum.customer: 'customer',
  TimelineEntryActorEnum.provider: 'provider',
  TimelineEntryActorEnum.system: 'system',
  TimelineEntryActorEnum.admin: 'admin',
};
