//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'price_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PriceSummary {
  /// Returns a new [PriceSummary] instance.
  PriceSummary({
    required this.subServiceId,

    required this.quantity,

    required this.unitPrice,

    required this.total,
  });

  @JsonKey(name: r'subServiceId', required: true, includeIfNull: false)
  final String subServiceId;

  @JsonKey(name: r'quantity', required: true, includeIfNull: false)
  final int quantity;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'unitPrice', required: true, includeIfNull: false)
  final int unitPrice;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PriceSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [subServiceId, quantity, unitPrice, total],
              [
                other.subServiceId,
                other.quantity,
                other.unitPrice,
                other.total,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([subServiceId, quantity, unitPrice, total]);

  factory PriceSummary.fromJson(Map<String, dynamic> json) =>
      _$PriceSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PriceSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
