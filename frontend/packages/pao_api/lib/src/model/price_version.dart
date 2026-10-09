//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'price_version.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PriceVersion {
  /// Returns a new [PriceVersion] instance.
  PriceVersion({
    required this.id,

    required this.subServiceId,

    required this.amount,

    required this.effectiveFrom,

    required this.createdBy,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'subServiceId', required: true, includeIfNull: false)
  final String subServiceId;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'effectiveFrom', required: true, includeIfNull: false)
  final DateTime effectiveFrom;

  @JsonKey(name: r'createdBy', required: true, includeIfNull: false)
  final String createdBy;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PriceVersion &&
            runtimeType == other.runtimeType &&
            equals(
              [id, subServiceId, amount, effectiveFrom, createdBy],
              [
                other.id,
                other.subServiceId,
                other.amount,
                other.effectiveFrom,
                other.createdBy,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, subServiceId, amount, effectiveFrom, createdBy]);

  factory PriceVersion.fromJson(Map<String, dynamic> json) =>
      _$PriceVersionFromJson(json);

  Map<String, dynamic> toJson() => _$PriceVersionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
