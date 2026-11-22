//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'icon_upload.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IconUpload {
  /// Returns a new [IconUpload] instance.
  IconUpload({required this.contentType, required this.data});

  @JsonKey(name: r'contentType', required: true, includeIfNull: false)
  final IconUploadContentTypeEnum contentType;

  /// The file, base64.
  @JsonKey(name: r'data', required: true, includeIfNull: false)
  final String data;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IconUpload &&
            runtimeType == other.runtimeType &&
            equals([contentType, data], [other.contentType, other.data]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([contentType, data]);

  factory IconUpload.fromJson(Map<String, dynamic> json) =>
      _$IconUploadFromJson(json);

  Map<String, dynamic> toJson() => _$IconUploadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum IconUploadContentTypeEnum {
  @JsonValue(r'image/svg+xml')
  imageSlashSvgPlusXml(r'image/svg+xml'),
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'image/webp')
  imageSlashWebp(r'image/webp');

  const IconUploadContentTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
