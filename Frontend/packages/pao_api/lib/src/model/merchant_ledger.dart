//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/ledger_entry_list.dart';
import 'package:pao_api/src/model/due_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'merchant_ledger.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MerchantLedger {
  /// Returns a new [MerchantLedger] instance.
  MerchantLedger({
    required this.providerId,

    required this.summary,

    required this.entries,
  });

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  @JsonKey(name: r'summary', required: true, includeIfNull: false)
  final DueSummary summary;

  @JsonKey(name: r'entries', required: true, includeIfNull: false)
  final LedgerEntryList entries;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MerchantLedger &&
            runtimeType == other.runtimeType &&
            equals(
              [providerId, summary, entries],
              [other.providerId, other.summary, other.entries],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([providerId, summary, entries]);

  factory MerchantLedger.fromJson(Map<String, dynamic> json) =>
      _$MerchantLedgerFromJson(json);

  Map<String, dynamic> toJson() => _$MerchantLedgerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
