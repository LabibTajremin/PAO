// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComplaintListCWProxy {
  ComplaintList items(List<Complaint> items);

  ComplaintList nextCursor(String? nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintList(...).copyWith(id: 12, name: "My name")
  /// ```
  ComplaintList call({List<Complaint> items, String? nextCursor});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComplaintList.copyWith(...)` or call `instanceOfComplaintList.copyWith.fieldName(value)` for a single field.
class _$ComplaintListCWProxyImpl implements _$ComplaintListCWProxy {
  const _$ComplaintListCWProxyImpl(this._value);

  final ComplaintList _value;

  @override
  ComplaintList items(List<Complaint> items) => call(items: items);

  @override
  ComplaintList nextCursor(String? nextCursor) => call(nextCursor: nextCursor);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComplaintList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComplaintList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComplaintList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return ComplaintList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Complaint>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $ComplaintListCopyWith on ComplaintList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComplaintList.copyWith(...)` or `instanceOfComplaintList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComplaintListCWProxy get copyWith => _$ComplaintListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintList _$ComplaintListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComplaintList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ComplaintList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ComplaintListToJson(ComplaintList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
