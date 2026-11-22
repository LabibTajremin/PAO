// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork_slot_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArtworkSlotListCWProxy {
  ArtworkSlotList slots(List<ArtworkSlot> slots);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkSlotList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkSlotList(...).copyWith(id: 12, name: "My name")
  /// ```
  ArtworkSlotList call({List<ArtworkSlot> slots});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfArtworkSlotList.copyWith(...)` or call `instanceOfArtworkSlotList.copyWith.fieldName(value)` for a single field.
class _$ArtworkSlotListCWProxyImpl implements _$ArtworkSlotListCWProxy {
  const _$ArtworkSlotListCWProxyImpl(this._value);

  final ArtworkSlotList _value;

  @override
  ArtworkSlotList slots(List<ArtworkSlot> slots) => call(slots: slots);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ArtworkSlotList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ArtworkSlotList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ArtworkSlotList call({Object? slots = const $CopyWithPlaceholder()}) {
    return ArtworkSlotList(
      slots: slots == const $CopyWithPlaceholder() || slots == null
          ? _value.slots
          // ignore: cast_nullable_to_non_nullable
          : slots as List<ArtworkSlot>,
    );
  }
}

extension $ArtworkSlotListCopyWith on ArtworkSlotList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfArtworkSlotList.copyWith(...)` or `instanceOfArtworkSlotList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArtworkSlotListCWProxy get copyWith => _$ArtworkSlotListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtworkSlotList _$ArtworkSlotListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtworkSlotList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['slots']);
      final val = ArtworkSlotList(
        slots: $checkedConvert(
          'slots',
          (v) => (v as List<dynamic>)
              .map((e) => ArtworkSlot.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ArtworkSlotListToJson(ArtworkSlotList instance) =>
    <String, dynamic>{'slots': instance.slots.map((e) => e.toJson()).toList()};
