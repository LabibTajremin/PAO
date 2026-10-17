//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/upload_purpose.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'upload_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadRequest {
  /// Returns a new [UploadRequest] instance.
  UploadRequest({
    required this.purpose,

    required this.contentType,

    required this.sizeBytes,
  });

  @JsonKey(name: r'purpose', required: true, includeIfNull: false)
  final UploadPurpose purpose;

  @JsonKey(name: r'contentType', required: true, includeIfNull: false)
  final UploadRequestContentTypeEnum contentType;

  // minimum: 1
  // maximum: 5242880
  @JsonKey(name: r'sizeBytes', required: true, includeIfNull: false)
  final int sizeBytes;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UploadRequest &&
            runtimeType == other.runtimeType &&
            equals(
              [purpose, contentType, sizeBytes],
              [other.purpose, other.contentType, other.sizeBytes],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([purpose, contentType, sizeBytes]);

  factory UploadRequest.fromJson(Map<String, dynamic> json) =>
      _$UploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UploadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum UploadRequestContentTypeEnum {
  @JsonValue(r'image/jpeg')
  imageSlashJpeg(r'image/jpeg'),
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'application/pdf')
  applicationSlashPdf(r'application/pdf');

  const UploadRequestContentTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
