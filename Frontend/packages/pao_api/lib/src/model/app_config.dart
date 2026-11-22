//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/artwork_image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'app_config.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppConfig {
  /// Returns a new [AppConfig] instance.
  AppConfig({required this.tagline, required this.artwork});

  @JsonKey(name: r'tagline', required: true, includeIfNull: false)
  final LocalizedText tagline;

  @JsonKey(name: r'artwork', required: true, includeIfNull: false)
  final List<ArtworkImage> artwork;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppConfig &&
            runtimeType == other.runtimeType &&
            equals([tagline, artwork], [other.tagline, other.artwork]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([tagline, artwork]);

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
