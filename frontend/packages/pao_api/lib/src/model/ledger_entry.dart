//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'ledger_entry.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LedgerEntry {
  /// Returns a new [LedgerEntry] instance.
  LedgerEntry({
    required this.id,

    required this.kind,

    required this.amount,

    this.bookingId,

    this.bookingNumber,

    this.jobTotal,

    this.submissionId,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  /// A commission is a debit; a confirmed payment is a credit.
  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final LedgerEntryKindEnum kind;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'bookingId', required: false, includeIfNull: false)
  final String? bookingId;

  @JsonKey(name: r'bookingNumber', required: false, includeIfNull: false)
  final String? bookingNumber;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'jobTotal', required: false, includeIfNull: false)
  final int? jobTotal;

  @JsonKey(name: r'submissionId', required: false, includeIfNull: false)
  final String? submissionId;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LedgerEntry &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                kind,
                amount,
                bookingId,
                bookingNumber,
                jobTotal,
                submissionId,
                createdAt,
              ],
              [
                other.id,
                other.kind,
                other.amount,
                other.bookingId,
                other.bookingNumber,
                other.jobTotal,
                other.submissionId,
                other.createdAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        kind,
        amount,
        bookingId,
        bookingNumber,
        jobTotal,
        submissionId,
        createdAt,
      ]);

  factory LedgerEntry.fromJson(Map<String, dynamic> json) =>
      _$LedgerEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// A commission is a debit; a confirmed payment is a credit.
enum LedgerEntryKindEnum {
  /// A commission is a debit; a confirmed payment is a credit.
  @JsonValue(r'commission')
  commission(r'commission'),

  /// A commission is a debit; a confirmed payment is a credit.
  @JsonValue(r'payment')
  payment(r'payment');

  const LedgerEntryKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
