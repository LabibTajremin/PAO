// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level2_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$Level2InfoCWProxy {
  Level2Info eligible(bool eligible);

  Level2Info nextSession(Level2Session? nextSession);

  Level2Info retryAfter(DateTime? retryAfter);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2Info(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2Info(...).copyWith(id: 12, name: "My name")
  /// ```
  Level2Info call({
    bool eligible,
    Level2Session? nextSession,
    DateTime? retryAfter,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLevel2Info.copyWith(...)` or call `instanceOfLevel2Info.copyWith.fieldName(value)` for a single field.
class _$Level2InfoCWProxyImpl implements _$Level2InfoCWProxy {
  const _$Level2InfoCWProxyImpl(this._value);

  final Level2Info _value;

  @override
  Level2Info eligible(bool eligible) => call(eligible: eligible);

  @override
  Level2Info nextSession(Level2Session? nextSession) =>
      call(nextSession: nextSession);

  @override
  Level2Info retryAfter(DateTime? retryAfter) => call(retryAfter: retryAfter);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Level2Info(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Level2Info(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Level2Info call({
    Object? eligible = const $CopyWithPlaceholder(),
    Object? nextSession = const $CopyWithPlaceholder(),
    Object? retryAfter = const $CopyWithPlaceholder(),
  }) {
    return Level2Info(
      eligible: eligible == const $CopyWithPlaceholder() || eligible == null
          ? _value.eligible
          // ignore: cast_nullable_to_non_nullable
          : eligible as bool,
      nextSession: nextSession == const $CopyWithPlaceholder()
          ? _value.nextSession
          // ignore: cast_nullable_to_non_nullable
          : nextSession as Level2Session?,
      retryAfter: retryAfter == const $CopyWithPlaceholder()
          ? _value.retryAfter
          // ignore: cast_nullable_to_non_nullable
          : retryAfter as DateTime?,
    );
  }
}

extension $Level2InfoCopyWith on Level2Info {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLevel2Info.copyWith(...)` or `instanceOfLevel2Info.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$Level2InfoCWProxy get copyWith => _$Level2InfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level2Info _$Level2InfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Level2Info', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['eligible']);
      final val = Level2Info(
        eligible: $checkedConvert('eligible', (v) => v as bool),
        nextSession: $checkedConvert(
          'nextSession',
          (v) => v == null
              ? null
              : Level2Session.fromJson(v as Map<String, dynamic>),
        ),
        retryAfter: $checkedConvert(
          'retryAfter',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$Level2InfoToJson(Level2Info instance) =>
    <String, dynamic>{
      'eligible': instance.eligible,
      'nextSession': ?instance.nextSession?.toJson(),
      'retryAfter': ?instance.retryAfter?.toIso8601String(),
    };
