//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'level2_session_checklist_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Level2SessionChecklistInner {
  /// Returns a new [Level2SessionChecklistInner] instance.
  Level2SessionChecklistInner({required this.item, required this.passed});

  @JsonKey(name: r'item', required: true, includeIfNull: false)
  final String item;

  @JsonKey(name: r'passed', required: true, includeIfNull: false)
  final bool passed;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Level2SessionChecklistInner &&
            runtimeType == other.runtimeType &&
            equals([item, passed], [other.item, other.passed]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([item, passed]);

  factory Level2SessionChecklistInner.fromJson(Map<String, dynamic> json) =>
      _$Level2SessionChecklistInnerFromJson(json);

  Map<String, dynamic> toJson() => _$Level2SessionChecklistInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
