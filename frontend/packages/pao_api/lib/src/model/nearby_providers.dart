//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/price_summary.dart';
import 'package:pao_api/src/model/provider_card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'nearby_providers.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NearbyProviders {
  /// Returns a new [NearbyProviders] instance.
  NearbyProviders({
    required this.items,

    required this.priceSummary,

    this.nextCursor,
  });

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ProviderCard> items;

  @JsonKey(name: r'priceSummary', required: true, includeIfNull: false)
  final PriceSummary priceSummary;

  /// Opaque cursor for the next page (base64 of created_at and id).
  @JsonKey(name: r'nextCursor', required: false, includeIfNull: false)
  final String? nextCursor;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NearbyProviders &&
            runtimeType == other.runtimeType &&
            equals(
              [items, priceSummary, nextCursor],
              [other.items, other.priceSummary, other.nextCursor],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([items, priceSummary, nextCursor]);

  factory NearbyProviders.fromJson(Map<String, dynamic> json) =>
      _$NearbyProvidersFromJson(json);

  Map<String, dynamic> toJson() => _$NearbyProvidersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
