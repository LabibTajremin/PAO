//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/sub_service.dart';
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/service_model.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'service.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Service {
  /// Returns a new [Service] instance.
  Service({
    required this.id,

    required this.categoryId,

    required this.name,

    required this.iconKey,

    required this.serviceModel,

    required this.requiredLevel,

    required this.searchRadiusM,

    required this.womenProvidersOnly,

    required this.requiresLevel2,

    this.level2Checklist,

    required this.published,

    this.subServices,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'categoryId', required: true, includeIfNull: false)
  final String categoryId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final LocalizedText name;

  @JsonKey(name: r'iconKey', required: true, includeIfNull: false)
  final String iconKey;

  @JsonKey(name: r'serviceModel', required: true, includeIfNull: false)
  final ServiceModel serviceModel;

  /// Verification level (PRD §6.1) — 0 Registered, 1 Verified, 2 PAO Verified Pro.
  // minimum: 0
  // maximum: 2
  @JsonKey(name: r'requiredLevel', required: true, includeIfNull: false)
  final int requiredLevel;

  // minimum: 500
  // maximum: 50000
  @JsonKey(name: r'searchRadiusM', required: true, includeIfNull: false)
  final int searchRadiusM;

  @JsonKey(name: r'womenProvidersOnly', required: true, includeIfNull: false)
  final bool womenProvidersOnly;

  @JsonKey(name: r'requiresLevel2', required: true, includeIfNull: false)
  final bool requiresLevel2;

  @JsonKey(name: r'level2Checklist', required: false, includeIfNull: false)
  final List<LocalizedText>? level2Checklist;

  @JsonKey(name: r'published', required: true, includeIfNull: false)
  final bool published;

  @JsonKey(name: r'subServices', required: false, includeIfNull: false)
  final List<SubService>? subServices;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Service &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                categoryId,
                name,
                iconKey,
                serviceModel,
                requiredLevel,
                searchRadiusM,
                womenProvidersOnly,
                requiresLevel2,
                level2Checklist,
                published,
                subServices,
              ],
              [
                other.id,
                other.categoryId,
                other.name,
                other.iconKey,
                other.serviceModel,
                other.requiredLevel,
                other.searchRadiusM,
                other.womenProvidersOnly,
                other.requiresLevel2,
                other.level2Checklist,
                other.published,
                other.subServices,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        categoryId,
        name,
        iconKey,
        serviceModel,
        requiredLevel,
        searchRadiusM,
        womenProvidersOnly,
        requiresLevel2,
        level2Checklist,
        published,
        subServices,
      ]);

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
