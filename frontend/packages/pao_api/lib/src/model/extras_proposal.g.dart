// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extras_proposal.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExtrasProposalCWProxy {
  ExtrasProposal id(String id);

  ExtrasProposal items(List<BookingItem> items);

  ExtrasProposal addedTotal(int addedTotal);

  ExtrasProposal newTotal(int newTotal);

  ExtrasProposal status(ExtrasProposalStatusEnum status);

  ExtrasProposal proposedAt(DateTime proposedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExtrasProposal(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExtrasProposal(...).copyWith(id: 12, name: "My name")
  /// ```
  ExtrasProposal call({
    String id,
    List<BookingItem> items,
    int addedTotal,
    int newTotal,
    ExtrasProposalStatusEnum status,
    DateTime proposedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfExtrasProposal.copyWith(...)` or call `instanceOfExtrasProposal.copyWith.fieldName(value)` for a single field.
class _$ExtrasProposalCWProxyImpl implements _$ExtrasProposalCWProxy {
  const _$ExtrasProposalCWProxyImpl(this._value);

  final ExtrasProposal _value;

  @override
  ExtrasProposal id(String id) => call(id: id);

  @override
  ExtrasProposal items(List<BookingItem> items) => call(items: items);

  @override
  ExtrasProposal addedTotal(int addedTotal) => call(addedTotal: addedTotal);

  @override
  ExtrasProposal newTotal(int newTotal) => call(newTotal: newTotal);

  @override
  ExtrasProposal status(ExtrasProposalStatusEnum status) =>
      call(status: status);

  @override
  ExtrasProposal proposedAt(DateTime proposedAt) =>
      call(proposedAt: proposedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExtrasProposal(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExtrasProposal(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ExtrasProposal call({
    Object? id = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? addedTotal = const $CopyWithPlaceholder(),
    Object? newTotal = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? proposedAt = const $CopyWithPlaceholder(),
  }) {
    return ExtrasProposal(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BookingItem>,
      addedTotal:
          addedTotal == const $CopyWithPlaceholder() || addedTotal == null
          ? _value.addedTotal
          // ignore: cast_nullable_to_non_nullable
          : addedTotal as int,
      newTotal: newTotal == const $CopyWithPlaceholder() || newTotal == null
          ? _value.newTotal
          // ignore: cast_nullable_to_non_nullable
          : newTotal as int,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ExtrasProposalStatusEnum,
      proposedAt:
          proposedAt == const $CopyWithPlaceholder() || proposedAt == null
          ? _value.proposedAt
          // ignore: cast_nullable_to_non_nullable
          : proposedAt as DateTime,
    );
  }
}

extension $ExtrasProposalCopyWith on ExtrasProposal {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfExtrasProposal.copyWith(...)` or `instanceOfExtrasProposal.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExtrasProposalCWProxy get copyWith => _$ExtrasProposalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtrasProposal _$ExtrasProposalFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExtrasProposal', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'items',
          'addedTotal',
          'newTotal',
          'status',
          'proposedAt',
        ],
      );
      final val = ExtrasProposal(
        id: $checkedConvert('id', (v) => v as String),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BookingItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        addedTotal: $checkedConvert('addedTotal', (v) => (v as num).toInt()),
        newTotal: $checkedConvert('newTotal', (v) => (v as num).toInt()),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$ExtrasProposalStatusEnumEnumMap, v),
        ),
        proposedAt: $checkedConvert(
          'proposedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExtrasProposalToJson(ExtrasProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'addedTotal': instance.addedTotal,
      'newTotal': instance.newTotal,
      'status': _$ExtrasProposalStatusEnumEnumMap[instance.status]!,
      'proposedAt': instance.proposedAt.toIso8601String(),
    };

const _$ExtrasProposalStatusEnumEnumMap = {
  ExtrasProposalStatusEnum.pending: 'pending',
  ExtrasProposalStatusEnum.approved: 'approved',
  ExtrasProposalStatusEnum.declined: 'declined',
};
