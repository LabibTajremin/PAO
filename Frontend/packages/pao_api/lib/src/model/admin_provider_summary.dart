//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/account_status.dart';
import 'package:pao_api/src/model/service_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_provider_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminProviderSummary {
  /// Returns a new [AdminProviderSummary] instance.
  AdminProviderSummary({
    required this.id,

    required this.name,

    this.phone,

    required this.status,

    required this.level,

    this.services,

    required this.rating,

    required this.completedJobs,

    required this.flaggedForReview,

    this.online,

    required this.createdAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AccountStatus status;

  /// Verification level (PRD §6.1) — 0 Registered, 1 Verified, 2 PAO Verified Pro.
  // minimum: 0
  // maximum: 2
  @JsonKey(name: r'level', required: true, includeIfNull: false)
  final int level;

  @JsonKey(name: r'services', required: false, includeIfNull: false)
  final List<ServiceRef>? services;

  @JsonKey(name: r'rating', required: true, includeIfNull: false)
  final double rating;

  @JsonKey(name: r'completedJobs', required: true, includeIfNull: false)
  final int completedJobs;

  @JsonKey(name: r'flaggedForReview', required: true, includeIfNull: false)
  final bool flaggedForReview;

  @JsonKey(name: r'online', required: false, includeIfNull: false)
  final bool? online;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminProviderSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                phone,
                status,
                level,
                services,
                rating,
                completedJobs,
                flaggedForReview,
                online,
                createdAt,
              ],
              [
                other.id,
                other.name,
                other.phone,
                other.status,
                other.level,
                other.services,
                other.rating,
                other.completedJobs,
                other.flaggedForReview,
                other.online,
                other.createdAt,
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
        status,
        level,
        services,
        rating,
        completedJobs,
        flaggedForReview,
        online,
        createdAt,
      ]);

  factory AdminProviderSummary.fromJson(Map<String, dynamic> json) =>
      _$AdminProviderSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AdminProviderSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
