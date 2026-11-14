//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'banner_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BannerInput {
  /// Returns a new [BannerInput] instance.
  BannerInput({
    required this.title,

    this.subtitle,

    this.imageUrl,

    this.serviceId,

    this.sortOrder,

    this.published,
  });

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final LocalizedText title;

  @JsonKey(name: r'subtitle', required: false, includeIfNull: false)
  final LocalizedText? subtitle;

  @JsonKey(name: r'imageUrl', required: false, includeIfNull: false)
  final String? imageUrl;

  @JsonKey(name: r'serviceId', required: false, includeIfNull: false)
  final String? serviceId;

  @JsonKey(name: r'sortOrder', required: false, includeIfNull: false)
  final int? sortOrder;

  @JsonKey(name: r'published', required: false, includeIfNull: false)
  final bool? published;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BannerInput &&
            runtimeType == other.runtimeType &&
            equals(
              [title, subtitle, imageUrl, serviceId, sortOrder, published],
              [
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
        title,
        subtitle,
        imageUrl,
        serviceId,
        sortOrder,
        published,
      ]);

  factory BannerInput.fromJson(Map<String, dynamic> json) =>
      _$BannerInputFromJson(json);

  Map<String, dynamic> toJson() => _$BannerInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
