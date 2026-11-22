//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'artwork_image.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ArtworkImage {
  /// Returns a new [ArtworkImage] instance.
  ArtworkImage({required this.key, required this.url, required this.version});

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  // minimum: 1
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ArtworkImage &&
            runtimeType == other.runtimeType &&
            equals([key, url, version], [other.key, other.url, other.version]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([key, url, version]);

  factory ArtworkImage.fromJson(Map<String, dynamic> json) =>
      _$ArtworkImageFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkImageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
