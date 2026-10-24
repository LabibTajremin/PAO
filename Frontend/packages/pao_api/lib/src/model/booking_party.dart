//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/badge.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'booking_party.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BookingParty {
  /// Returns a new [BookingParty] instance.
  BookingParty({
    required this.id,

    required this.name,

    this.photoUrl,

    this.phone,

    this.badge,

    this.rating,

    this.ratingCount,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'photoUrl', required: false, includeIfNull: false)
  final String? photoUrl;

  /// Shown to the other side only after acceptance (PRD §5 step 6).
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'badge', required: false, includeIfNull: false)
  final Badge? badge;

  @JsonKey(name: r'rating', required: false, includeIfNull: false)
  final double? rating;

  @JsonKey(name: r'ratingCount', required: false, includeIfNull: false)
  final int? ratingCount;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BookingParty &&
            runtimeType == other.runtimeType &&
            equals(
              [id, name, photoUrl, phone, badge, rating, ratingCount],
              [
                other.id,
                other.name,
                other.photoUrl,
                other.phone,
                other.badge,
                other.rating,
                other.ratingCount,
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
        phone,
        badge,
        rating,
        ratingCount,
      ]);

  factory BookingParty.fromJson(Map<String, dynamic> json) =>
      _$BookingPartyFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPartyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
