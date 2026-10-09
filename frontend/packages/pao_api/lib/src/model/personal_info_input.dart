//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/gender.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'personal_info_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalInfoInput {
  /// Returns a new [PersonalInfoInput] instance.
  PersonalInfoInput({
    required this.fullName,

    required this.dateOfBirth,

    required this.gender,

    required this.presentAddress,

    required this.permanentAddress,

    this.bio,
  });

  /// Name exactly as on the NID.
  @JsonKey(name: r'fullName', required: true, includeIfNull: false)
  final String fullName;

  @JsonKey(name: r'dateOfBirth', required: true, includeIfNull: false)
  final DateTime dateOfBirth;

  @JsonKey(name: r'gender', required: true, includeIfNull: false)
  final Gender gender;

  @JsonKey(name: r'presentAddress', required: true, includeIfNull: false)
  final String presentAddress;

  @JsonKey(name: r'permanentAddress', required: true, includeIfNull: false)
  final String permanentAddress;

  @JsonKey(name: r'bio', required: false, includeIfNull: false)
  final String? bio;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PersonalInfoInput &&
            runtimeType == other.runtimeType &&
            equals(
              [
                fullName,
                dateOfBirth,
                gender,
                presentAddress,
                permanentAddress,
                bio,
              ],
              [
                other.fullName,
                other.dateOfBirth,
                other.gender,
                other.presentAddress,
                other.permanentAddress,
                other.bio,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        fullName,
        dateOfBirth,
        gender,
        presentAddress,
        permanentAddress,
        bio,
      ]);

  factory PersonalInfoInput.fromJson(Map<String, dynamic> json) =>
      _$PersonalInfoInputFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalInfoInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
