//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/sub_service.dart';
import 'package:pao_api/src/model/service.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'catalog_search_results.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogSearchResults {
  /// Returns a new [CatalogSearchResults] instance.
  CatalogSearchResults({required this.services, required this.subServices});

  @JsonKey(name: r'services', required: true, includeIfNull: false)
  final List<Service> services;

  @JsonKey(name: r'subServices', required: true, includeIfNull: false)
  final List<SubService> subServices;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CatalogSearchResults &&
            runtimeType == other.runtimeType &&
            equals(
              [services, subServices],
              [other.services, other.subServices],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([services, subServices]);

  factory CatalogSearchResults.fromJson(Map<String, dynamic> json) =>
      _$CatalogSearchResultsFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogSearchResultsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
