// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DueSummaryCWProxy {
  DueSummary due(int due);

  DueSummary blockAmount(int blockAmount);

  DueSummary blocked(bool blocked);

  DueSummary commissionRateBp(int commissionRateBp);

  DueSummary pendingPayments(int pendingPayments);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DueSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DueSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  DueSummary call({
    int due,
    int blockAmount,
    bool blocked,
    int commissionRateBp,
    int pendingPayments,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDueSummary.copyWith(...)` or call `instanceOfDueSummary.copyWith.fieldName(value)` for a single field.
class _$DueSummaryCWProxyImpl implements _$DueSummaryCWProxy {
  const _$DueSummaryCWProxyImpl(this._value);

  final DueSummary _value;

  @override
  DueSummary due(int due) => call(due: due);

  @override
  DueSummary blockAmount(int blockAmount) => call(blockAmount: blockAmount);

  @override
  DueSummary blocked(bool blocked) => call(blocked: blocked);

  @override
  DueSummary commissionRateBp(int commissionRateBp) =>
      call(commissionRateBp: commissionRateBp);

  @override
  DueSummary pendingPayments(int pendingPayments) =>
      call(pendingPayments: pendingPayments);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DueSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DueSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DueSummary call({
    Object? due = const $CopyWithPlaceholder(),
    Object? blockAmount = const $CopyWithPlaceholder(),
    Object? blocked = const $CopyWithPlaceholder(),
    Object? commissionRateBp = const $CopyWithPlaceholder(),
    Object? pendingPayments = const $CopyWithPlaceholder(),
  }) {
    return DueSummary(
      due: due == const $CopyWithPlaceholder() || due == null
          ? _value.due
          // ignore: cast_nullable_to_non_nullable
          : due as int,
      blockAmount:
          blockAmount == const $CopyWithPlaceholder() || blockAmount == null
          ? _value.blockAmount
          // ignore: cast_nullable_to_non_nullable
          : blockAmount as int,
      blocked: blocked == const $CopyWithPlaceholder() || blocked == null
          ? _value.blocked
          // ignore: cast_nullable_to_non_nullable
          : blocked as bool,
      commissionRateBp:
          commissionRateBp == const $CopyWithPlaceholder() ||
              commissionRateBp == null
          ? _value.commissionRateBp
          // ignore: cast_nullable_to_non_nullable
          : commissionRateBp as int,
      pendingPayments:
          pendingPayments == const $CopyWithPlaceholder() ||
              pendingPayments == null
          ? _value.pendingPayments
          // ignore: cast_nullable_to_non_nullable
          : pendingPayments as int,
    );
  }
}

extension $DueSummaryCopyWith on DueSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDueSummary.copyWith(...)` or `instanceOfDueSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DueSummaryCWProxy get copyWith => _$DueSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DueSummary _$DueSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DueSummary', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'due',
          'blockAmount',
          'blocked',
          'commissionRateBp',
          'pendingPayments',
        ],
      );
      final val = DueSummary(
        due: $checkedConvert('due', (v) => (v as num).toInt()),
        blockAmount: $checkedConvert('blockAmount', (v) => (v as num).toInt()),
        blocked: $checkedConvert('blocked', (v) => v as bool),
        commissionRateBp: $checkedConvert(
          'commissionRateBp',
          (v) => (v as num).toInt(),
        ),
        pendingPayments: $checkedConvert(
          'pendingPayments',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DueSummaryToJson(DueSummary instance) =>
    <String, dynamic>{
      'due': instance.due,
      'blockAmount': instance.blockAmount,
      'blocked': instance.blocked,
      'commissionRateBp': instance.commissionRateBp,
      'pendingPayments': instance.pendingPayments,
    };
