//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'catalog_icon.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogIcon {
  /// Returns a new [CatalogIcon] instance.
  CatalogIcon({required this.iconUrl, required this.contentType});

  @JsonKey(name: r'iconUrl', required: true, includeIfNull: false)
  final String iconUrl;

  @JsonKey(name: r'contentType', required: true, includeIfNull: false)
  final CatalogIconContentTypeEnum contentType;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CatalogIcon &&
            runtimeType == other.runtimeType &&
            equals([iconUrl, contentType], [other.iconUrl, other.contentType]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([iconUrl, contentType]);

  factory CatalogIcon.fromJson(Map<String, dynamic> json) =>
      _$CatalogIconFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogIconToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CatalogIconContentTypeEnum {
  @JsonValue(r'image/svg+xml')
  imageSlashSvgPlusXml(r'image/svg+xml'),
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'image/webp')
  imageSlashWebp(r'image/webp');

  const CatalogIconContentTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
