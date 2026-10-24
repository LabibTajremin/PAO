//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/language.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'provider_profile_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderProfileUpdate {
  /// Returns a new [ProviderProfileUpdate] instance.
  ProviderProfileUpdate({this.bio, this.photoMediaId, required this.language});

  @JsonKey(name: r'bio', required: false, includeIfNull: false)
  final String? bio;

  @JsonKey(name: r'photoMediaId', required: false, includeIfNull: false)
  final String? photoMediaId;

  @JsonKey(name: r'language', required: true, includeIfNull: false)
  final Language language;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProviderProfileUpdate &&
            runtimeType == other.runtimeType &&
            equals(
              [bio, photoMediaId, language],
              [other.bio, other.photoMediaId, other.language],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([bio, photoMediaId, language]);

  factory ProviderProfileUpdate.fromJson(Map<String, dynamic> json) =>
      _$ProviderProfileUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderProfileUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
