//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reject_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RejectInput {
  /// Returns a new [RejectInput] instance.
  RejectInput({required this.reason, this.note});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final RejectInputReasonEnum reason;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RejectInput &&
            runtimeType == other.runtimeType &&
            equals([reason, note], [other.reason, other.note]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([reason, note]);

  factory RejectInput.fromJson(Map<String, dynamic> json) =>
      _$RejectInputFromJson(json);

  Map<String, dynamic> toJson() => _$RejectInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RejectInputReasonEnum {
  @JsonValue(r'busy')
  busy(r'busy'),
  @JsonValue(r'too_far')
  tooFar(r'too_far'),
  @JsonValue(r'not_my_service')
  notMyService(r'not_my_service'),
  @JsonValue(r'other')
  other(r'other');

  const RejectInputReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
