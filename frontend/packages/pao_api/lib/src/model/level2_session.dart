//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/level2_session_checklist_inner.dart';
import 'package:pao_api/src/model/level2_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'level2_session.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Level2Session {
  /// Returns a new [Level2Session] instance.
  Level2Session({
    required this.id,

    required this.providerId,

    required this.serviceId,

    required this.scheduledAt,

    required this.location,

    required this.status,

    this.result,

    this.checklist,

    this.notes,

    this.decidedBy,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  @JsonKey(name: r'serviceId', required: true, includeIfNull: false)
  final String serviceId;

  @JsonKey(name: r'scheduledAt', required: true, includeIfNull: false)
  final DateTime scheduledAt;

  @JsonKey(name: r'location', required: true, includeIfNull: false)
  final String location;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final Level2SessionStatusEnum status;

  @JsonKey(name: r'result', required: false, includeIfNull: false)
  final Level2Result? result;

  @JsonKey(name: r'checklist', required: false, includeIfNull: false)
  final List<Level2SessionChecklistInner>? checklist;

  @JsonKey(name: r'notes', required: false, includeIfNull: false)
  final String? notes;

  @JsonKey(name: r'decidedBy', required: false, includeIfNull: false)
  final String? decidedBy;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Level2Session &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                providerId,
                serviceId,
                scheduledAt,
                location,
                status,
                result,
                checklist,
                notes,
                decidedBy,
              ],
              [
                other.id,
                other.providerId,
                other.serviceId,
                other.scheduledAt,
                other.location,
                other.status,
                other.result,
                other.checklist,
                other.notes,
                other.decidedBy,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        providerId,
        serviceId,
        scheduledAt,
        location,
        status,
        result,
        checklist,
        notes,
        decidedBy,
      ]);

  factory Level2Session.fromJson(Map<String, dynamic> json) =>
      _$Level2SessionFromJson(json);

  Map<String, dynamic> toJson() => _$Level2SessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum Level2SessionStatusEnum {
  @JsonValue(r'scheduled')
  scheduled(r'scheduled'),
  @JsonValue(r'completed')
  completed(r'completed'),
  @JsonValue(r'cancelled')
  cancelled(r'cancelled');

  const Level2SessionStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
