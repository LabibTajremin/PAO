//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'setting.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Setting {
  /// Returns a new [Setting] instance.
  Setting({
    required this.key,

    required this.value,

    required this.type,

    required this.description,

    this.updatedAt,

    this.updatedBy,
  });

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  /// The value encoded as text; `type` says how to read it.
  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final SettingTypeEnum type;

  @JsonKey(name: r'description', required: true, includeIfNull: false)
  final String description;

  @JsonKey(name: r'updatedAt', required: false, includeIfNull: false)
  final DateTime? updatedAt;

  @JsonKey(name: r'updatedBy', required: false, includeIfNull: false)
  final String? updatedBy;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Setting &&
            runtimeType == other.runtimeType &&
            equals(
              [key, value, type, description, updatedAt, updatedBy],
              [
                other.key,
                other.value,
                other.type,
                other.description,
                other.updatedAt,
                other.updatedBy,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([key, value, type, description, updatedAt, updatedBy]);

  factory Setting.fromJson(Map<String, dynamic> json) =>
      _$SettingFromJson(json);

  Map<String, dynamic> toJson() => _$SettingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SettingTypeEnum {
  @JsonValue(r'integer')
  integer(r'integer'),
  @JsonValue(r'number')
  number(r'number'),
  @JsonValue(r'boolean')
  boolean(r'boolean'),
  @JsonValue(r'string')
  string(r'string'),
  @JsonValue(r'geojson')
  geojson(r'geojson');

  const SettingTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
