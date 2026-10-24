//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/upload_purpose.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'media_object.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MediaObject {
  /// Returns a new [MediaObject] instance.
  MediaObject({
    required this.id,

    required this.purpose,

    required this.contentType,

    required this.sizeBytes,

    required this.status,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'purpose', required: true, includeIfNull: false)
  final UploadPurpose purpose;

  @JsonKey(name: r'contentType', required: true, includeIfNull: false)
  final String contentType;

  @JsonKey(name: r'sizeBytes', required: true, includeIfNull: false)
  final int sizeBytes;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final MediaObjectStatusEnum status;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MediaObject &&
            runtimeType == other.runtimeType &&
            equals(
              [id, purpose, contentType, sizeBytes, status],
              [
                other.id,
                other.purpose,
                other.contentType,
                other.sizeBytes,
                other.status,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, purpose, contentType, sizeBytes, status]);

  factory MediaObject.fromJson(Map<String, dynamic> json) =>
      _$MediaObjectFromJson(json);

  Map<String, dynamic> toJson() => _$MediaObjectToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MediaObjectStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'confirmed')
  confirmed(r'confirmed');

  const MediaObjectStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
