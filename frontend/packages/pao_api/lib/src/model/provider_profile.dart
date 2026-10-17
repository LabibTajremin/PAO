//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/account_status.dart';
import 'package:pao_api/src/model/badge.dart';
import 'package:pao_api/src/model/service_ref.dart';
import 'package:pao_api/src/model/point.dart';
import 'package:pao_api/src/model/language.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'provider_profile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderProfile {
  /// Returns a new [ProviderProfile] instance.
  ProviderProfile({
    required this.id,

    required this.name,

    required this.phone,

    this.photoUrl,

    this.bio,

    required this.status,

    required this.level,

    required this.badge,

    required this.online,

    required this.language,

    required this.services,

    required this.experienceYears,

    this.homeBase,

    this.workingRadiusM,

    this.flaggedForReview,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'photoUrl', required: false, includeIfNull: false)
  final String? photoUrl;

  @JsonKey(name: r'bio', required: false, includeIfNull: false)
  final String? bio;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AccountStatus status;

  /// Verification level (PRD §6.1) — 0 Registered, 1 Verified, 2 PAO Verified Pro.
  // minimum: 0
  // maximum: 2
  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final int level;

  @JsonKey(name: r'badge', required: true, includeIfNull: false)
  final Badge badge;

  @JsonKey(name: r'online', required: true, includeIfNull: false)
  final bool online;

  @JsonKey(name: r'language', required: true, includeIfNull: false)
  final Language language;

  @JsonKey(name: r'services', required: true, includeIfNull: false)
  final List<ServiceRef> services;

  @JsonKey(name: r'experienceYears', required: true, includeIfNull: false)
  final int experienceYears;

  @JsonKey(name: r'homeBase', required: false, includeIfNull: false)
  final Point? homeBase;

  @JsonKey(name: r'workingRadiusM', required: false, includeIfNull: false)
  final int? workingRadiusM;

  @JsonKey(name: r'flaggedForReview', required: false, includeIfNull: false)
  final bool? flaggedForReview;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProviderProfile &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                phone,
                photoUrl,
                bio,
                status,
                level,
                badge,
                online,
                language,
                services,
                experienceYears,
                homeBase,
                workingRadiusM,
                flaggedForReview,
              ],
              [
                other.id,
                other.name,
                other.phone,
                other.photoUrl,
                other.bio,
                other.status,
                other.level,
                other.badge,
                other.online,
                other.language,
                other.services,
                other.experienceYears,
                other.homeBase,
                other.workingRadiusM,
                other.flaggedForReview,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        name,
        phone,
        photoUrl,
        bio,
        status,
        level,
        badge,
        online,
        language,
        services,
        experienceYears,
        homeBase,
        workingRadiusM,
        flaggedForReview,
      ]);

  factory ProviderProfile.fromJson(Map<String, dynamic> json) =>
      _$ProviderProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
