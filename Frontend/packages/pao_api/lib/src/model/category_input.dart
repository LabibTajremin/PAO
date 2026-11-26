//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'category_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CategoryInput {
  /// Returns a new [CategoryInput] instance.
  CategoryInput({
    required this.name,

    required this.iconKey,

    this.iconUrl,

    this.sortOrder,

    this.published,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final LocalizedText name;

  @JsonKey(name: r'iconKey', required: true, includeIfNull: false)
  final String iconKey;

  /// An iconUrl returned by the icon endpoints; absent uses iconKey.
  @JsonKey(name: r'iconUrl', required: false, includeIfNull: false)
  final String? iconUrl;

  @JsonKey(name: r'sortOrder', required: false, includeIfNull: false)
  final int? sortOrder;

  @JsonKey(name: r'published', required: false, includeIfNull: false)
  final bool? published;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategoryInput &&
            runtimeType == other.runtimeType &&
            equals(
              [name, iconKey, iconUrl, sortOrder, published],
              [
                other.name,
                other.iconKey,
                other.iconUrl,
                other.sortOrder,
                other.published,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([name, iconKey, iconUrl, sortOrder, published]);

  factory CategoryInput.fromJson(Map<String, dynamic> json) =>
      _$CategoryInputFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
