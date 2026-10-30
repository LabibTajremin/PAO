//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complete_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompleteInput {
  /// Returns a new [CompleteInput] instance.
  CompleteInput({required this.cashReceived});

  /// Must be true — the provider confirms cash was received (D4).
  @JsonKey(name: r'cashReceived', required: true, includeIfNull: false)
  final bool cashReceived;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CompleteInput &&
            runtimeType == other.runtimeType &&
            equals([cashReceived], [other.cashReceived]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([cashReceived]);

  factory CompleteInput.fromJson(Map<String, dynamic> json) =>
      _$CompleteInputFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
