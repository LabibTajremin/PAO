//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'status_reason.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StatusReason {
  /// Returns a new [StatusReason] instance.
  StatusReason({required this.reason});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StatusReason &&
            runtimeType == other.runtimeType &&
            equals([reason], [other.reason]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([reason]);

  factory StatusReason.fromJson(Map<String, dynamic> json) =>
      _$StatusReasonFromJson(json);

  Map<String, dynamic> toJson() => _$StatusReasonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
