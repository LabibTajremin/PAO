//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'due_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DueSummary {
  /// Returns a new [DueSummary] instance.
  DueSummary({
    required this.due,

    required this.blockAmount,

    required this.blocked,

    required this.commissionRateBp,

    required this.pendingPayments,
  });

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'due', required: true, includeIfNull: false)
  final int due;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'blockAmount', required: true, includeIfNull: false)
  final int blockAmount;

  @JsonKey(name: r'blocked', required: true, includeIfNull: false)
  final bool blocked;

  // minimum: 0
  // maximum: 10000
  @JsonKey(name: r'commissionRateBp', required: true, includeIfNull: false)
  final int commissionRateBp;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'pendingPayments', required: true, includeIfNull: false)
  final int pendingPayments;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DueSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [due, blockAmount, blocked, commissionRateBp, pendingPayments],
              [
                other.due,
                other.blockAmount,
                other.blocked,
                other.commissionRateBp,
                other.pendingPayments,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        due,
        blockAmount,
        blocked,
        commissionRateBp,
        pendingPayments,
      ]);

  factory DueSummary.fromJson(Map<String, dynamic> json) =>
      _$DueSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$DueSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
