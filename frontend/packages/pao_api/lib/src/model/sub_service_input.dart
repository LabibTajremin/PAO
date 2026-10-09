//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/price_unit.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'sub_service_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubServiceInput {
  /// Returns a new [SubServiceInput] instance.
  SubServiceInput({
    required this.serviceId,

    required this.name,

    this.description,

    this.inclusions,

    this.exclusions,

    required this.unit,

    this.maxQuantity,

    this.initialPrice,

    this.published,
  });

  @JsonKey(name: r'serviceId', required: true, includeIfNull: false)
  final String serviceId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final LocalizedText name;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final LocalizedText? description;

  @JsonKey(name: r'inclusions', required: false, includeIfNull: false)
  final List<LocalizedText>? inclusions;

  @JsonKey(name: r'exclusions', required: false, includeIfNull: false)
  final List<LocalizedText>? exclusions;

  @JsonKey(name: r'unit', required: true, includeIfNull: false)
  final PriceUnit unit;

  // minimum: 1
  @JsonKey(name: r'maxQuantity', required: false, includeIfNull: false)
  final int? maxQuantity;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'initialPrice', required: false, includeIfNull: false)
  final int? initialPrice;

  @JsonKey(name: r'published', required: false, includeIfNull: false)
  final bool? published;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubServiceInput &&
            runtimeType == other.runtimeType &&
            equals(
              [
                serviceId,
                name,
                description,
                inclusions,
                exclusions,
                unit,
                maxQuantity,
                initialPrice,
                published,
              ],
              [
                other.serviceId,
                other.name,
                other.description,
                other.inclusions,
                other.exclusions,
                other.unit,
                other.maxQuantity,
                other.initialPrice,
                other.published,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        serviceId,
        name,
        description,
        inclusions,
        exclusions,
        unit,
        maxQuantity,
        initialPrice,
        published,
      ]);

  factory SubServiceInput.fromJson(Map<String, dynamic> json) =>
      _$SubServiceInputFromJson(json);

  Map<String, dynamic> toJson() => _$SubServiceInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
