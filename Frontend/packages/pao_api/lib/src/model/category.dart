//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:pao_api/src/model/service.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'category.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Category {
  /// Returns a new [Category] instance.
  Category({
    required this.id,

    required this.name,

    required this.iconKey,

    required this.sortOrder,

    required this.published,

    required this.services,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final LocalizedText name;

  @JsonKey(name: r'iconKey', required: true, includeIfNull: false)
  final String iconKey;

  @JsonKey(name: r'sortOrder', required: true, includeIfNull: false)
  final int sortOrder;

  @JsonKey(name: r'published', required: true, includeIfNull: false)
  final bool published;

  @JsonKey(name: r'services', required: true, includeIfNull: false)
  final List<Service> services;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Category &&
            runtimeType == other.runtimeType &&
            equals(
              [id, name, iconKey, sortOrder, published, services],
              [
                other.id,
                other.name,
                other.iconKey,
                other.sortOrder,
                other.published,
                other.services,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, name, iconKey, sortOrder, published, services]);

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
