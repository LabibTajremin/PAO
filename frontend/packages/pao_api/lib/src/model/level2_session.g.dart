// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level2_session.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Level2SessionCWProxy {
  Level2Session id(String id);

  Level2Session providerId(String providerId);

  Level2Session serviceId(String serviceId);

  Level2Session scheduledAt(DateTime scheduledAt);

  Level2Session location(String location);

  Level2Session status(Level2SessionStatusEnum status);

  Level2Session result(Level2Result? result);

  Level2Session checklist(List<Level2SessionChecklistInner>? checklist);

  Level2Session notes(String? notes);

  Level2Session decidedBy(String? decidedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2Session(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2Session(...).copyWith(id: 12, name: "My name")
  /// ```
  Level2Session call({
    String id,
    String providerId,
    String serviceId,
    DateTime scheduledAt,
    String location,
    Level2SessionStatusEnum status,
    Level2Result? result,
    List<Level2SessionChecklistInner>? checklist,
    String? notes,
    String? decidedBy,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLevel2Session.copyWith(...)` or call `instanceOfLevel2Session.copyWith.fieldName(value)` for a single field.
class _$Level2SessionCWProxyImpl implements _$Level2SessionCWProxy {
  const _$Level2SessionCWProxyImpl(this._value);

  final Level2Session _value;

  @override
  Level2Session id(String id) => call(id: id);

  @override
  Level2Session providerId(String providerId) => call(providerId: providerId);

  @override
  Level2Session serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  Level2Session scheduledAt(DateTime scheduledAt) =>
      call(scheduledAt: scheduledAt);

  @override
  Level2Session location(String location) => call(location: location);

  @override
  Level2Session status(Level2SessionStatusEnum status) => call(status: status);

  @override
  Level2Session result(Level2Result? result) => call(result: result);

  @override
  Level2Session checklist(List<Level2SessionChecklistInner>? checklist) =>
      call(checklist: checklist);

  @override
  Level2Session notes(String? notes) => call(notes: notes);

  @override
  Level2Session decidedBy(String? decidedBy) => call(decidedBy: decidedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2Session(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2Session(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Level2Session call({
    Object? id = const $CopyWithPlaceholder(),
    Object? providerId = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? scheduledAt = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? result = const $CopyWithPlaceholder(),
    Object? checklist = const $CopyWithPlaceholder(),
    Object? notes = const $CopyWithPlaceholder(),
    Object? decidedBy = const $CopyWithPlaceholder(),
  }) {
    return Level2Session(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      providerId:
          providerId == const $CopyWithPlaceholder() || providerId == null
          ? _value.providerId
          // ignore: cast_nullable_to_non_nullable
          : providerId as String,
      serviceId: serviceId == const $CopyWithPlaceholder() || serviceId == null
          ? _value.serviceId
          // ignore: cast_nullable_to_non_nullable
          : serviceId as String,
      scheduledAt:
          scheduledAt == const $CopyWithPlaceholder() || scheduledAt == null
          ? _value.scheduledAt
          // ignore: cast_nullable_to_non_nullable
          : scheduledAt as DateTime,
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as Level2SessionStatusEnum,
      result: result == const $CopyWithPlaceholder()
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as Level2Result?,
      checklist: checklist == const $CopyWithPlaceholder()
          ? _value.checklist
          // ignore: cast_nullable_to_non_nullable
          : checklist as List<Level2SessionChecklistInner>?,
      notes: notes == const $CopyWithPlaceholder()
          ? _value.notes
          // ignore: cast_nullable_to_non_nullable
          : notes as String?,
      decidedBy: decidedBy == const $CopyWithPlaceholder()
          ? _value.decidedBy
          // ignore: cast_nullable_to_non_nullable
          : decidedBy as String?,
    );
  }
}

extension $Level2SessionCopyWith on Level2Session {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLevel2Session.copyWith(...)` or `instanceOfLevel2Session.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Level2SessionCWProxy get copyWith => _$Level2SessionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level2Session _$Level2SessionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Level2Session', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'providerId',
          'serviceId',
          'scheduledAt',
          'location',
          'status',
        ],
      );
      final val = Level2Session(
        id: $checkedConvert('id', (v) => v as String),
        providerId: $checkedConvert('providerId', (v) => v as String),
        serviceId: $checkedConvert('serviceId', (v) => v as String),
        scheduledAt: $checkedConvert(
          'scheduledAt',
          (v) => DateTime.parse(v as String),
        ),
        location: $checkedConvert('location', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$Level2SessionStatusEnumEnumMap, v),
        ),
        result: $checkedConvert(
          'result',
          (v) => $enumDecodeNullable(_$Level2ResultEnumMap, v),
        ),
        checklist: $checkedConvert(
          'checklist',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => Level2SessionChecklistInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        notes: $checkedConvert('notes', (v) => v as String?),
        decidedBy: $checkedConvert('decidedBy', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$Level2SessionToJson(Level2Session instance) =>
    <String, dynamic>{
      'id': instance.id,
      'providerId': instance.providerId,
      'serviceId': instance.serviceId,
      'scheduledAt': instance.scheduledAt.toIso8601String(),
      'location': instance.location,
      'status': _$Level2SessionStatusEnumEnumMap[instance.status]!,
      'result': ?_$Level2ResultEnumMap[instance.result],
      'checklist': ?instance.checklist?.map((e) => e.toJson()).toList(),
      'notes': ?instance.notes,
      'decidedBy': ?instance.decidedBy,
    };

const _$Level2SessionStatusEnumEnumMap = {
  Level2SessionStatusEnum.scheduled: 'scheduled',
  Level2SessionStatusEnum.completed: 'completed',
  Level2SessionStatusEnum.cancelled: 'cancelled',
};

const _$Level2ResultEnumMap = {
  Level2Result.pass: 'pass',
  Level2Result.fail: 'fail',
  Level2Result.retest: 'retest',
};
