//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'audit_entry.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuditEntry {
  /// Returns a new [AuditEntry] instance.
  AuditEntry({
    required this.id,

    required this.at,

    this.actorId,

    this.actorRole,

    required this.action,

    required this.subjectType,

    required this.subjectId,

    this.reason,

    this.before,

    this.after,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @JsonKey(name: r'actorId', required: false, includeIfNull: false)
  final String? actorId;

  @JsonKey(name: r'actorRole', required: false, includeIfNull: false)
  final String? actorRole;

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  @JsonKey(name: r'subjectType', required: true, includeIfNull: false)
  final String subjectType;

  @JsonKey(name: r'subjectId', required: true, includeIfNull: false)
  final String subjectId;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @JsonKey(name: r'before', required: false, includeIfNull: false)
  final Map<String, Object>? before;

  @JsonKey(name: r'after', required: false, includeIfNull: false)
  final Map<String, Object>? after;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuditEntry &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                at,
                actorId,
                actorRole,
                action,
                subjectType,
                subjectId,
                reason,
                before,
                after,
              ],
              [
                other.id,
                other.at,
                other.actorId,
                other.actorRole,
                other.action,
                other.subjectType,
                other.subjectId,
                other.reason,
                other.before,
                other.after,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        at,
        actorId,
        actorRole,
        action,
        subjectType,
        subjectId,
        reason,
        before,
        after,
      ]);

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);

  Map<String, dynamic> toJson() => _$AuditEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
