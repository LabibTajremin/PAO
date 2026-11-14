//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/banner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'banner_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BannerList {
  /// Returns a new [BannerList] instance.
  BannerList({required this.banners});

  @JsonKey(name: r'banners', required: true, includeIfNull: false)
  final List<Banner> banners;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BannerList &&
            runtimeType == other.runtimeType &&
            equals([banners], [other.banners]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([banners]);

  factory BannerList.fromJson(Map<String, dynamic> json) =>
      _$BannerListFromJson(json);

  Map<String, dynamic> toJson() => _$BannerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
