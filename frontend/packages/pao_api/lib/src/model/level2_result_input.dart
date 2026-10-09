//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/point.dart';
import 'package:pao_api/src/model/level2_result.dart';
import 'package:pao_api/src/model/level2_result_input_checklist_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'level2_result_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Level2ResultInput {
  /// Returns a new [Level2ResultInput] instance.
  Level2ResultInput({
    required this.result,

    required this.checklist,

    this.notes,

    this.visitLocation,

    this.photoMediaIds,
  });

  @JsonKey(name: r'result', required: true, includeIfNull: false)
  final Level2Result result;

  @JsonKey(name: r'checklist', required: true, includeIfNull: false)
  final List<Level2ResultInputChecklistInner> checklist;

  @JsonKey(name: r'notes', required: false, includeIfNull: false)
  final String? notes;

  @JsonKey(name: r'visitLocation', required: false, includeIfNull: false)
  final Point? visitLocation;

  @JsonKey(name: r'photoMediaIds', required: false, includeIfNull: false)
  final List<String>? photoMediaIds;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Level2ResultInput &&
            runtimeType == other.runtimeType &&
            equals(
              [result, checklist, notes, visitLocation, photoMediaIds],
              [
                other.result,
                other.checklist,
                other.notes,
                other.visitLocation,
                other.photoMediaIds,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        result,
        checklist,
        notes,
        visitLocation,
        photoMediaIds,
      ]);

  factory Level2ResultInput.fromJson(Map<String, dynamic> json) =>
      _$Level2ResultInputFromJson(json);

  Map<String, dynamic> toJson() => _$Level2ResultInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
