// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level2_session_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Level2SessionInputCWProxy {
  Level2SessionInput providerId(String providerId);

  Level2SessionInput serviceId(String serviceId);

  Level2SessionInput scheduledAt(DateTime scheduledAt);

  Level2SessionInput location(String location);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2SessionInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2SessionInput(...).copyWith(id: 12, name: "My name")
  /// ```
  Level2SessionInput call({
    String providerId,
    String serviceId,
    DateTime scheduledAt,
    String location,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLevel2SessionInput.copyWith(...)` or call `instanceOfLevel2SessionInput.copyWith.fieldName(value)` for a single field.
class _$Level2SessionInputCWProxyImpl implements _$Level2SessionInputCWProxy {
  const _$Level2SessionInputCWProxyImpl(this._value);

  final Level2SessionInput _value;

  @override
  Level2SessionInput providerId(String providerId) =>
      call(providerId: providerId);

  @override
  Level2SessionInput serviceId(String serviceId) => call(serviceId: serviceId);

  @override
  Level2SessionInput scheduledAt(DateTime scheduledAt) =>
      call(scheduledAt: scheduledAt);

  @override
  Level2SessionInput location(String location) => call(location: location);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2SessionInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2SessionInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Level2SessionInput call({
    Object? providerId = const $CopyWithPlaceholder(),
    Object? serviceId = const $CopyWithPlaceholder(),
    Object? scheduledAt = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
  }) {
    return Level2SessionInput(
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
    );
  }
}

extension $Level2SessionInputCopyWith on Level2SessionInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLevel2SessionInput.copyWith(...)` or `instanceOfLevel2SessionInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Level2SessionInputCWProxy get copyWith =>
      _$Level2SessionInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level2SessionInput _$Level2SessionInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Level2SessionInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'providerId',
          'serviceId',
          'scheduledAt',
          'location',
        ],
      );
      final val = Level2SessionInput(
        providerId: $checkedConvert('providerId', (v) => v as String),
        serviceId: $checkedConvert('serviceId', (v) => v as String),
        scheduledAt: $checkedConvert(
          'scheduledAt',
          (v) => DateTime.parse(v as String),
        ),
        location: $checkedConvert('location', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$Level2SessionInputToJson(Level2SessionInput instance) =>
    <String, dynamic>{
      'providerId': instance.providerId,
      'serviceId': instance.serviceId,
      'scheduledAt': instance.scheduledAt.toIso8601String(),
      'location': instance.location,
    };
