//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/category.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'catalog_tree.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogTree {
  /// Returns a new [CatalogTree] instance.
  CatalogTree({required this.version, required this.categories});

  /// Bumped on every catalog change.
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  @JsonKey(name: r'categories', required: true, includeIfNull: false)
  final List<Category> categories;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CatalogTree &&
            runtimeType == other.runtimeType &&
            equals([version, categories], [other.version, other.categories]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([version, categories]);

  factory CatalogTree.fromJson(Map<String, dynamic> json) =>
      _$CatalogTreeFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogTreeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
