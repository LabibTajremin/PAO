//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'banner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Banner {
  /// Returns a new [Banner] instance.
  Banner({
    required this.id,

    required this.title,

    this.subtitle,

    this.imageUrl,

    this.serviceId,

    required this.sortOrder,

    required this.published,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final LocalizedText title;

  @JsonKey(name: r'subtitle', required: false, includeIfNull: false)
  final LocalizedText? subtitle;

  @JsonKey(name: r'imageUrl', required: false, includeIfNull: false)
  final String? imageUrl;

  /// The service the banner opens.
  @JsonKey(name: r'serviceId', required: false, includeIfNull: false)
  final String? serviceId;

  @JsonKey(name: r'sortOrder', required: true, includeIfNull: false)
  final int sortOrder;

  @JsonKey(name: r'published', required: true, includeIfNull: false)
  final bool published;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Banner &&
            runtimeType == other.runtimeType &&
            equals(
              [id, title, subtitle, imageUrl, serviceId, sortOrder, published],
              [
                other.id,
                other.title,
                other.subtitle,
                other.imageUrl,
                other.serviceId,
                other.sortOrder,
                other.published,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        title,
        subtitle,
        imageUrl,
        serviceId,
        sortOrder,
        published,
      ]);

  factory Banner.fromJson(Map<String, dynamic> json) => _$BannerFromJson(json);

  Map<String, dynamic> toJson() => _$BannerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
