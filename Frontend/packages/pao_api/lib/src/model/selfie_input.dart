//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'selfie_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SelfieInput {
  /// Returns a new [SelfieInput] instance.
  SelfieInput({required this.mediaId});

  @JsonKey(name: r'mediaId', required: true, includeIfNull: false)
  final String mediaId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SelfieInput &&
            runtimeType == other.runtimeType &&
            equals([mediaId], [other.mediaId]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([mediaId]);

  factory SelfieInput.fromJson(Map<String, dynamic> json) =>
      _$SelfieInputFromJson(json);

  Map<String, dynamic> toJson() => _$SelfieInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
