//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'icon_library.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IconLibrary {
  /// Returns a new [IconLibrary] instance.
  IconLibrary({required this.keys});

  @JsonKey(name: r'keys', required: true, includeIfNull: false)
  final List<String> keys;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IconLibrary &&
            runtimeType == other.runtimeType &&
            equals([keys], [other.keys]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([keys]);

  factory IconLibrary.fromJson(Map<String, dynamic> json) =>
      _$IconLibraryFromJson(json);

  Map<String, dynamic> toJson() => _$IconLibraryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
