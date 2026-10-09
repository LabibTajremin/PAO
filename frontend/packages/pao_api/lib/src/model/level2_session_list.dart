//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/level2_session.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'level2_session_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Level2SessionList {
  /// Returns a new [Level2SessionList] instance.
  Level2SessionList({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<Level2Session> items;

  /// Opaque cursor for the next page (base64 of created_at and id).
  @JsonKey(name: r'nextCursor', required: false, includeIfNull: false)
  final String? nextCursor;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Level2SessionList &&
            runtimeType == other.runtimeType &&
            equals([items, nextCursor], [other.items, other.nextCursor]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([items, nextCursor]);

  factory Level2SessionList.fromJson(Map<String, dynamic> json) =>
      _$Level2SessionListFromJson(json);

  Map<String, dynamic> toJson() => _$Level2SessionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
