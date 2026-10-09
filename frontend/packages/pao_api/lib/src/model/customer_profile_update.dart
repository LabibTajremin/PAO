//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/language.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_profile_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerProfileUpdate {
  /// Returns a new [CustomerProfileUpdate] instance.
  CustomerProfileUpdate({
    required this.name,

    this.photoMediaId,

    required this.language,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// A confirmed upload with purpose `avatar`.
  @JsonKey(name: r'photoMediaId', required: false, includeIfNull: false)
  final String? photoMediaId;

  @JsonKey(name: r'language', required: true, includeIfNull: false)
  final Language language;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerProfileUpdate &&
            runtimeType == other.runtimeType &&
            equals(
              [name, photoMediaId, language],
              [other.name, other.photoMediaId, other.language],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, photoMediaId, language]);

  factory CustomerProfileUpdate.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerProfileUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
