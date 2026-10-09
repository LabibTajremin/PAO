//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'view_url.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ViewUrl {
  /// Returns a new [ViewUrl] instance.
  ViewUrl({required this.url, required this.expiresAt});

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  @JsonKey(name: r'expiresAt', required: true, includeIfNull: false)
  final DateTime expiresAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ViewUrl &&
            runtimeType == other.runtimeType &&
            equals([url, expiresAt], [other.url, other.expiresAt]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([url, expiresAt]);

  factory ViewUrl.fromJson(Map<String, dynamic> json) =>
      _$ViewUrlFromJson(json);

  Map<String, dynamic> toJson() => _$ViewUrlToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
