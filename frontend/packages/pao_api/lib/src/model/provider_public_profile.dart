//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/badge.dart';
import 'package:pao_api/src/model/service_ref.dart';
import 'package:pao_api/src/model/rating_breakdown.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'provider_public_profile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderPublicProfile {
  /// Returns a new [ProviderPublicProfile] instance.
  ProviderPublicProfile({
    required this.id,

    required this.name,

    this.photoUrl,

    required this.badge,

    required this.level,

    required this.bio,

    required this.experienceYears,

    required this.services,

    required this.rating,

    required this.completedJobs,

    required this.memberSince,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'photoUrl', required: false, includeIfNull: false)
  final String? photoUrl;

  @JsonKey(name: r'badge', required: true, includeIfNull: false)
  final Badge badge;

  /// Verification level (PRD §6.1) — 0 Registered, 1 Verified, 2 PAO Verified Pro.
  // minimum: 0
  // maximum: 2
  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final int level;

  @JsonKey(name: r'bio', required: true, includeIfNull: false)
  final String bio;

  @JsonKey(name: r'experienceYears', required: true, includeIfNull: false)
  final int experienceYears;

  @JsonKey(name: r'services', required: true, includeIfNull: false)
  final List<ServiceRef> services;

  @JsonKey(name: r'rating', required: true, includeIfNull: false)
  final RatingBreakdown rating;

  @JsonKey(name: r'completedJobs', required: true, includeIfNull: false)
  final int completedJobs;

  @JsonKey(name: r'memberSince', required: true, includeIfNull: false)
  final DateTime memberSince;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProviderPublicProfile &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                photoUrl,
                badge,
                level,
                bio,
                experienceYears,
                services,
                rating,
                completedJobs,
                memberSince,
              ],
              [
                other.id,
                other.name,
                other.photoUrl,
                other.badge,
                other.level,
                other.bio,
                other.experienceYears,
                other.services,
                other.rating,
                other.completedJobs,
                other.memberSince,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        name,
        photoUrl,
        badge,
        level,
        bio,
        experienceYears,
        services,
        rating,
        completedJobs,
        memberSince,
      ]);

  factory ProviderPublicProfile.fromJson(Map<String, dynamic> json) =>
      _$ProviderPublicProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderPublicProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
