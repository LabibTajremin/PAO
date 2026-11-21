//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'icon_link.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IconLink {
  /// Returns a new [IconLink] instance.
  IconLink({required this.url});

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IconLink &&
            runtimeType == other.runtimeType &&
            equals([url], [other.url]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([url]);

  factory IconLink.fromJson(Map<String, dynamic> json) =>
      _$IconLinkFromJson(json);

  Map<String, dynamic> toJson() => _$IconLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
