//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'artwork_upload.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ArtworkUpload {
  /// Returns a new [ArtworkUpload] instance.
  ArtworkUpload({required this.contentType, required this.data});

  @JsonKey(name: r'contentType', required: true, includeIfNull: false)
  final ArtworkUploadContentTypeEnum contentType;

  /// The file, base64.
  @JsonKey(name: r'data', required: true, includeIfNull: false)
  final String data;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ArtworkUpload &&
            runtimeType == other.runtimeType &&
            equals([contentType, data], [other.contentType, other.data]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([contentType, data]);

  factory ArtworkUpload.fromJson(Map<String, dynamic> json) =>
      _$ArtworkUploadFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkUploadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ArtworkUploadContentTypeEnum {
  @JsonValue(r'image/svg+xml')
  imageSlashSvgPlusXml(r'image/svg+xml'),
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'image/webp')
  imageSlashWebp(r'image/webp');

  const ArtworkUploadContentTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
