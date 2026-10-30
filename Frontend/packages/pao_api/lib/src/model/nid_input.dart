//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'nid_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NidInput {
  /// Returns a new [NidInput] instance.
  NidInput({
    required this.nidNumber,

    required this.frontMediaId,

    required this.backMediaId,
  });

  @JsonKey(name: r'nidNumber', required: true, includeIfNull: false)
  final String nidNumber;

  @JsonKey(name: r'frontMediaId', required: true, includeIfNull: false)
  final String frontMediaId;

  @JsonKey(name: r'backMediaId', required: true, includeIfNull: false)
  final String backMediaId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NidInput &&
            runtimeType == other.runtimeType &&
            equals(
              [nidNumber, frontMediaId, backMediaId],
              [other.nidNumber, other.frontMediaId, other.backMediaId],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([nidNumber, frontMediaId, backMediaId]);

  factory NidInput.fromJson(Map<String, dynamic> json) =>
      _$NidInputFromJson(json);

  Map<String, dynamic> toJson() => _$NidInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
