// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LedgerEntryCWProxy {
  LedgerEntry id(String id);

  LedgerEntry kind(LedgerEntryKindEnum kind);

  LedgerEntry amount(int amount);

  LedgerEntry bookingId(String? bookingId);

  LedgerEntry bookingNumber(String? bookingNumber);

  LedgerEntry jobTotal(int? jobTotal);

  LedgerEntry submissionId(String? submissionId);

  LedgerEntry createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LedgerEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LedgerEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  LedgerEntry call({
    String id,
    LedgerEntryKindEnum kind,
    int amount,
    String? bookingId,
    String? bookingNumber,
    int? jobTotal,
    String? submissionId,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLedgerEntry.copyWith(...)` or call `instanceOfLedgerEntry.copyWith.fieldName(value)` for a single field.
class _$LedgerEntryCWProxyImpl implements _$LedgerEntryCWProxy {
  const _$LedgerEntryCWProxyImpl(this._value);

  final LedgerEntry _value;

  @override
  LedgerEntry id(String id) => call(id: id);

  @override
  LedgerEntry kind(LedgerEntryKindEnum kind) => call(kind: kind);

  @override
  LedgerEntry amount(int amount) => call(amount: amount);

  @override
  LedgerEntry bookingId(String? bookingId) => call(bookingId: bookingId);

  @override
  LedgerEntry bookingNumber(String? bookingNumber) =>
      call(bookingNumber: bookingNumber);

  @override
  LedgerEntry jobTotal(int? jobTotal) => call(jobTotal: jobTotal);

  @override
  LedgerEntry submissionId(String? submissionId) =>
      call(submissionId: submissionId);

  @override
  LedgerEntry createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LedgerEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LedgerEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LedgerEntry call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? bookingNumber = const $CopyWithPlaceholder(),
    Object? jobTotal = const $CopyWithPlaceholder(),
    Object? submissionId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return LedgerEntry(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as LedgerEntryKindEnum,
      amount: amount == const $CopyWithPlaceholder() || amount == null
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      bookingId: bookingId == const $CopyWithPlaceholder()
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String?,
      bookingNumber: bookingNumber == const $CopyWithPlaceholder()
          ? _value.bookingNumber
          // ignore: cast_nullable_to_non_nullable
          : bookingNumber as String?,
      jobTotal: jobTotal == const $CopyWithPlaceholder()
          ? _value.jobTotal
          // ignore: cast_nullable_to_non_nullable
          : jobTotal as int?,
      submissionId: submissionId == const $CopyWithPlaceholder()
          ? _value.submissionId
          // ignore: cast_nullable_to_non_nullable
          : submissionId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $LedgerEntryCopyWith on LedgerEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLedgerEntry.copyWith(...)` or `instanceOfLedgerEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LedgerEntryCWProxy get copyWith => _$LedgerEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedgerEntry _$LedgerEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LedgerEntry', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'kind', 'amount', 'createdAt']);
  final val = LedgerEntry(
    id: $checkedConvert('id', (v) => v as String),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$LedgerEntryKindEnumEnumMap, v),
    ),
    amount: $checkedConvert('amount', (v) => (v as num).toInt()),
    bookingId: $checkedConvert('bookingId', (v) => v as String?),
    bookingNumber: $checkedConvert('bookingNumber', (v) => v as String?),
    jobTotal: $checkedConvert('jobTotal', (v) => (v as num?)?.toInt()),
    submissionId: $checkedConvert('submissionId', (v) => v as String?),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$LedgerEntryToJson(LedgerEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$LedgerEntryKindEnumEnumMap[instance.kind]!,
      'amount': instance.amount,
      'bookingId': ?instance.bookingId,
      'bookingNumber': ?instance.bookingNumber,
      'jobTotal': ?instance.jobTotal,
      'submissionId': ?instance.submissionId,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$LedgerEntryKindEnumEnumMap = {
  LedgerEntryKindEnum.commission: 'commission',
  LedgerEntryKindEnum.payment: 'payment',
};
