//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/localized_text.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'service_ref.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServiceRef {
  /// Returns a new [ServiceRef] instance.
  ServiceRef({required this.id, required this.name});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final LocalizedText name;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceRef &&
            runtimeType == other.runtimeType &&
            equals([id, name], [other.id, other.name]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([id, name]);

  factory ServiceRef.fromJson(Map<String, dynamic> json) =>
      _$ServiceRefFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
