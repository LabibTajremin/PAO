//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/badge.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'provider_card.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderCard {
  /// Returns a new [ProviderCard] instance.
  ProviderCard({
    required this.id,

    required this.name,

    this.photoUrl,

    required this.badge,

    required this.level,

    required this.rating,

    required this.ratingCount,

    required this.completedJobs,

    required this.distanceM,
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

  @JsonKey(name: r'rating', required: true, includeIfNull: false)
  final double rating;

  @JsonKey(name: r'ratingCount', required: true, includeIfNull: false)
  final int ratingCount;

  @JsonKey(name: r'completedJobs', required: true, includeIfNull: false)
  final int completedJobs;

  @JsonKey(name: r'distanceM', required: true, includeIfNull: false)
  final int distanceM;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProviderCard &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                photoUrl,
                badge,
                level,
                rating,
                ratingCount,
                completedJobs,
                distanceM,
              ],
              [
                other.id,
                other.name,
                other.photoUrl,
                other.badge,
                other.level,
                other.rating,
                other.ratingCount,
                other.completedJobs,
                other.distanceM,
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
        rating,
        ratingCount,
        completedJobs,
        distanceM,
      ]);

  factory ProviderCard.fromJson(Map<String, dynamic> json) =>
      _$ProviderCardFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderCardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
