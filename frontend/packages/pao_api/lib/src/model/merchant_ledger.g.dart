// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_ledger.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MerchantLedgerCWProxy {
  MerchantLedger providerId(String providerId);

  MerchantLedger summary(DueSummary summary);

  MerchantLedger entries(LedgerEntryList entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MerchantLedger(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MerchantLedger(...).copyWith(id: 12, name: "My name")
  /// ```
  MerchantLedger call({
    String providerId,
    DueSummary summary,
    LedgerEntryList entries,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMerchantLedger.copyWith(...)` or call `instanceOfMerchantLedger.copyWith.fieldName(value)` for a single field.
class _$MerchantLedgerCWProxyImpl implements _$MerchantLedgerCWProxy {
  const _$MerchantLedgerCWProxyImpl(this._value);

  final MerchantLedger _value;

  @override
  MerchantLedger providerId(String providerId) => call(providerId: providerId);

  @override
  MerchantLedger summary(DueSummary summary) => call(summary: summary);

  @override
  MerchantLedger entries(LedgerEntryList entries) => call(entries: entries);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MerchantLedger(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MerchantLedger(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MerchantLedger call({
    Object? providerId = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? entries = const $CopyWithPlaceholder(),
  }) {
    return MerchantLedger(
      providerId:
          providerId == const $CopyWithPlaceholder() || providerId == null
          ? _value.providerId
          // ignore: cast_nullable_to_non_nullable
          : providerId as String,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as DueSummary,
      entries: entries == const $CopyWithPlaceholder() || entries == null
          ? _value.entries
          // ignore: cast_nullable_to_non_nullable
          : entries as LedgerEntryList,
    );
  }
}

extension $MerchantLedgerCopyWith on MerchantLedger {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMerchantLedger.copyWith(...)` or `instanceOfMerchantLedger.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MerchantLedgerCWProxy get copyWith => _$MerchantLedgerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchantLedger _$MerchantLedgerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MerchantLedger', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['providerId', 'summary', 'entries'],
      );
      final val = MerchantLedger(
        providerId: $checkedConvert('providerId', (v) => v as String),
        summary: $checkedConvert(
          'summary',
          (v) => DueSummary.fromJson(v as Map<String, dynamic>),
        ),
        entries: $checkedConvert(
          'entries',
          (v) => LedgerEntryList.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MerchantLedgerToJson(MerchantLedger instance) =>
    <String, dynamic>{
      'providerId': instance.providerId,
      'summary': instance.summary.toJson(),
      'entries': instance.entries.toJson(),
    };
