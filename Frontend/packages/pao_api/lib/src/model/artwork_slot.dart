//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/app_name.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'artwork_slot.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ArtworkSlot {
  /// Returns a new [ArtworkSlot] instance.
  ArtworkSlot({
    required this.key,

    required this.app,

    required this.width,

    required this.height,

    this.url,

    this.contentType,

    required this.version,

    required this.replaced,
  });

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  @JsonKey(name: r'app', required: true, includeIfNull: false)
  final AppName app;

  @JsonKey(name: r'width', required: true, includeIfNull: false)
  final int width;

  @JsonKey(name: r'height', required: true, includeIfNull: false)
  final int height;

  /// Absent until seeded or uploaded.
  @JsonKey(name: r'url', required: false, includeIfNull: false)
  final String? url;

  @JsonKey(name: r'contentType', required: false, includeIfNull: false)
  final ArtworkSlotContentTypeEnum? contentType;

  /// 0 until the slot has an image.
  // minimum: 0
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  /// An admin uploaded it; seeding leaves it alone.
  @JsonKey(name: r'replaced', required: true, includeIfNull: false)
  final bool replaced;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ArtworkSlot &&
            runtimeType == other.runtimeType &&
            equals(
              [key, app, width, height, url, contentType, version, replaced],
              [
                other.key,
                other.app,
                other.width,
                other.height,
                other.url,
                other.contentType,
                other.version,
                other.replaced,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        key,
        app,
        width,
        height,
        url,
        contentType,
        version,
        replaced,
      ]);

  factory ArtworkSlot.fromJson(Map<String, dynamic> json) =>
      _$ArtworkSlotFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkSlotToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ArtworkSlotContentTypeEnum {
  @JsonValue(r'image/svg+xml')
  imageSlashSvgPlusXml(r'image/svg+xml'),
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'image/webp')
  imageSlashWebp(r'image/webp');

  const ArtworkSlotContentTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
