//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'emergency_contact_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmergencyContactInput {
  /// Returns a new [EmergencyContactInput] instance.
  EmergencyContactInput({
    required this.name,

    required this.relation,

    required this.phone,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'relation', required: true, includeIfNull: false)
  final String relation;

  /// Bangladeshi mobile number; the API normalises to +8801XXXXXXXXX.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EmergencyContactInput &&
            runtimeType == other.runtimeType &&
            equals(
              [name, relation, phone],
              [other.name, other.relation, other.phone],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, relation, phone]);

  factory EmergencyContactInput.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactInputFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
