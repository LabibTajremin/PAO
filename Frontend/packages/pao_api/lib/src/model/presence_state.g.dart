// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PresenceStateCWProxy {
  PresenceState online(bool online);

  PresenceState heartbeatIntervalSeconds(int? heartbeatIntervalSeconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PresenceState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PresenceState(...).copyWith(id: 12, name: "My name")
  /// ```
  PresenceState call({bool online, int? heartbeatIntervalSeconds});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPresenceState.copyWith(...)` or call `instanceOfPresenceState.copyWith.fieldName(value)` for a single field.
class _$PresenceStateCWProxyImpl implements _$PresenceStateCWProxy {
  const _$PresenceStateCWProxyImpl(this._value);

  final PresenceState _value;

  @override
  PresenceState online(bool online) => call(online: online);

  @override
  PresenceState heartbeatIntervalSeconds(int? heartbeatIntervalSeconds) =>
      call(heartbeatIntervalSeconds: heartbeatIntervalSeconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PresenceState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PresenceState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PresenceState call({
    Object? online = const $CopyWithPlaceholder(),
    Object? heartbeatIntervalSeconds = const $CopyWithPlaceholder(),
  }) {
    return PresenceState(
      online: online == const $CopyWithPlaceholder() || online == null
          ? _value.online
          // ignore: cast_nullable_to_non_nullable
          : online as bool,
      heartbeatIntervalSeconds:
          heartbeatIntervalSeconds == const $CopyWithPlaceholder()
          ? _value.heartbeatIntervalSeconds
          // ignore: cast_nullable_to_non_nullable
          : heartbeatIntervalSeconds as int?,
    );
  }
}

extension $PresenceStateCopyWith on PresenceState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPresenceState.copyWith(...)` or `instanceOfPresenceState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PresenceStateCWProxy get copyWith => _$PresenceStateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresenceState _$PresenceStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PresenceState', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['online']);
      final val = PresenceState(
        online: $checkedConvert('online', (v) => v as bool),
        heartbeatIntervalSeconds: $checkedConvert(
          'heartbeatIntervalSeconds',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PresenceStateToJson(PresenceState instance) =>
    <String, dynamic>{
      'online': instance.online,
      'heartbeatIntervalSeconds': ?instance.heartbeatIntervalSeconds,
    };
