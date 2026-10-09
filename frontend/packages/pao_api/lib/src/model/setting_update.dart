//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'setting_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SettingUpdate {
  /// Returns a new [SettingUpdate] instance.
  SettingUpdate({required this.value});

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingUpdate &&
            runtimeType == other.runtimeType &&
            equals([value], [other.value]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([value]);

  factory SettingUpdate.fromJson(Map<String, dynamic> json) =>
      _$SettingUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$SettingUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
