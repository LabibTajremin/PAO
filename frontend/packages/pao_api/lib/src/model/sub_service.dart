//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/price_unit.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'sub_service.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubService {
  /// Returns a new [SubService] instance.
  SubService({
    required this.id,

    required this.serviceId,

    required this.name,

    this.description,

    this.inclusions,

    this.exclusions,

    required this.unit,

    required this.price,

    required this.priceVersionId,

    this.maxQuantity,

    required this.published,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

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

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'price', required: true, includeIfNull: false)
  final int price;

  @JsonKey(name: r'priceVersionId', required: true, includeIfNull: false)
  final String priceVersionId;

  // minimum: 1
  @JsonKey(name: r'maxQuantity', required: false, includeIfNull: false)
  final int? maxQuantity;

  @JsonKey(name: r'published', required: true, includeIfNull: false)
  final bool published;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubService &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                serviceId,
                name,
                description,
                inclusions,
                exclusions,
                unit,
                price,
                priceVersionId,
                maxQuantity,
                published,
              ],
              [
                other.id,
                other.serviceId,
                other.name,
                other.description,
                other.inclusions,
                other.exclusions,
                other.unit,
                other.price,
                other.priceVersionId,
                other.maxQuantity,
                other.published,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        serviceId,
        name,
        description,
        inclusions,
        exclusions,
        unit,
        price,
        priceVersionId,
        maxQuantity,
        published,
      ]);

  factory SubService.fromJson(Map<String, dynamic> json) =>
      _$SubServiceFromJson(json);

  Map<String, dynamic> toJson() => _$SubServiceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
