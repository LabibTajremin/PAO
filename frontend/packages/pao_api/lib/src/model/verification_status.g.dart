// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerificationStatusCWProxy {
  VerificationStatus level(int level);

  VerificationStatus badge(Badge badge);

  VerificationStatus items(List<VerificationItem> items);

  VerificationStatus canReceiveBookings(bool canReceiveBookings);

  VerificationStatus level2(Level2Info? level2);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  VerificationStatus call({
    int level,
    Badge badge,
    List<VerificationItem> items,
    bool canReceiveBookings,
    Level2Info? level2,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVerificationStatus.copyWith(...)` or call `instanceOfVerificationStatus.copyWith.fieldName(value)` for a single field.
class _$VerificationStatusCWProxyImpl implements _$VerificationStatusCWProxy {
  const _$VerificationStatusCWProxyImpl(this._value);

  final VerificationStatus _value;

  @override
  VerificationStatus level(int level) => call(level: level);

  @override
  VerificationStatus badge(Badge badge) => call(badge: badge);

  @override
  VerificationStatus items(List<VerificationItem> items) => call(items: items);

  @override
  VerificationStatus canReceiveBookings(bool canReceiveBookings) =>
      call(canReceiveBookings: canReceiveBookings);

  @override
  VerificationStatus level2(Level2Info? level2) => call(level2: level2);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VerificationStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VerificationStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VerificationStatus call({
    Object? level = const $CopyWithPlaceholder(),
    Object? badge = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? canReceiveBookings = const $CopyWithPlaceholder(),
    Object? level2 = const $CopyWithPlaceholder(),
  }) {
    return VerificationStatus(
      level: level == const $CopyWithPlaceholder() || level == null
          ? _value.level
          // ignore: cast_nullable_to_non_nullable
          : level as int,
      badge: badge == const $CopyWithPlaceholder() || badge == null
          ? _value.badge
          // ignore: cast_nullable_to_non_nullable
          : badge as Badge,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<VerificationItem>,
      canReceiveBookings:
          canReceiveBookings == const $CopyWithPlaceholder() ||
              canReceiveBookings == null
          ? _value.canReceiveBookings
          // ignore: cast_nullable_to_non_nullable
          : canReceiveBookings as bool,
      level2: level2 == const $CopyWithPlaceholder()
          ? _value.level2
          // ignore: cast_nullable_to_non_nullable
          : level2 as Level2Info?,
    );
  }
}

extension $VerificationStatusCopyWith on VerificationStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVerificationStatus.copyWith(...)` or `instanceOfVerificationStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerificationStatusCWProxy get copyWith =>
      _$VerificationStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerificationStatus _$VerificationStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VerificationStatus', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['level', 'badge', 'items', 'canReceiveBookings'],
      );
      final val = VerificationStatus(
        level: $checkedConvert('level', (v) => (v as num).toInt()),
        badge: $checkedConvert('badge', (v) => $enumDecode(_$BadgeEnumMap, v)),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => VerificationItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        canReceiveBookings: $checkedConvert(
          'canReceiveBookings',
          (v) => v as bool,
        ),
        level2: $checkedConvert(
          'level2',
          (v) =>
              v == null ? null : Level2Info.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$VerificationStatusToJson(VerificationStatus instance) =>
    <String, dynamic>{
      'level': instance.level,
      'badge': _$BadgeEnumMap[instance.badge]!,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'canReceiveBookings': instance.canReceiveBookings,
      'level2': ?instance.level2?.toJson(),
    };

const _$BadgeEnumMap = {
  Badge.none: 'none',
  Badge.verified: 'verified',
  Badge.verifiedPro: 'verified_pro',
};
