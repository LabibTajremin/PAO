//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'localized_text.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalizedText {
  /// Returns a new [LocalizedText] instance.
  LocalizedText({required this.en, required this.bn});

  @JsonKey(name: r'en', required: true, includeIfNull: false)
  final String en;

  @JsonKey(name: r'bn', required: true, includeIfNull: false)
  final String bn;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LocalizedText &&
            runtimeType == other.runtimeType &&
            equals([en, bn], [other.en, other.bn]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([en, bn]);

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
