//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/level2_session.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'level2_info.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Level2Info {
  /// Returns a new [Level2Info] instance.
  Level2Info({required this.eligible, this.nextSession, this.retryAfter});

  @JsonKey(name: r'eligible', required: true, includeIfNull: false)
  final bool eligible;

  @JsonKey(name: r'nextSession', required: false, includeIfNull: false)
  final Level2Session? nextSession;

  /// End of the cooling-off period after a failed session.
  @JsonKey(name: r'retryAfter', required: false, includeIfNull: false)
  final DateTime? retryAfter;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Level2Info &&
            runtimeType == other.runtimeType &&
            equals(
              [eligible, nextSession, retryAfter],
              [other.eligible, other.nextSession, other.retryAfter],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([eligible, nextSession, retryAfter]);

  factory Level2Info.fromJson(Map<String, dynamic> json) =>
      _$Level2InfoFromJson(json);

  Map<String, dynamic> toJson() => _$Level2InfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
