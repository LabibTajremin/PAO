//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/language.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_profile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerProfile {
  /// Returns a new [CustomerProfile] instance.
  CustomerProfile({
    required this.id,

    required this.name,

    this.phone,

    this.photoUrl,

    required this.language,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  /// Short-lived signed URL of the profile photo.
  @JsonKey(name: r'photoUrl', required: false, includeIfNull: false)
  final String? photoUrl;

  @JsonKey(name: r'language', required: true, includeIfNull: false)
  final Language language;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerProfile &&
            runtimeType == other.runtimeType &&
            equals(
              [id, name, phone, photoUrl, language],
              [
                other.id,
                other.name,
                other.phone,
                other.photoUrl,
                other.language,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, name, phone, photoUrl, language]);

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
