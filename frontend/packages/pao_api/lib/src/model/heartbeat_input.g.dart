// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heartbeat_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HeartbeatInputCWProxy {
  HeartbeatInput location(Point location);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `HeartbeatInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// HeartbeatInput(...).copyWith(id: 12, name: "My name")
  /// ```
  HeartbeatInput call({Point location});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfHeartbeatInput.copyWith(...)` or call `instanceOfHeartbeatInput.copyWith.fieldName(value)` for a single field.
class _$HeartbeatInputCWProxyImpl implements _$HeartbeatInputCWProxy {
  const _$HeartbeatInputCWProxyImpl(this._value);

  final HeartbeatInput _value;

  @override
  HeartbeatInput location(Point location) => call(location: location);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `HeartbeatInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// HeartbeatInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  HeartbeatInput call({Object? location = const $CopyWithPlaceholder()}) {
    return HeartbeatInput(
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as Point,
    );
  }
}

extension $HeartbeatInputCopyWith on HeartbeatInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfHeartbeatInput.copyWith(...)` or `instanceOfHeartbeatInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HeartbeatInputCWProxy get copyWith => _$HeartbeatInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HeartbeatInput _$HeartbeatInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HeartbeatInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['location']);
      final val = HeartbeatInput(
        location: $checkedConvert(
          'location',
          (v) => Point.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HeartbeatInputToJson(HeartbeatInput instance) =>
    <String, dynamic>{'location': instance.location.toJson()};
