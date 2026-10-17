//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'timeline_entry.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TimelineEntry {
  /// Returns a new [TimelineEntry] instance.
  TimelineEntry({
    required this.status,

    required this.at,

    required this.actor,

    this.reason,
  });

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final BookingStatus status;

  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @JsonKey(name: r'actor', required: true, includeIfNull: false)
  final TimelineEntryActorEnum actor;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TimelineEntry &&
            runtimeType == other.runtimeType &&
            equals(
              [status, at, actor, reason],
              [other.status, other.at, other.actor, other.reason],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([status, at, actor, reason]);

  factory TimelineEntry.fromJson(Map<String, dynamic> json) =>
      _$TimelineEntryFromJson(json);

  Map<String, dynamic> toJson() => _$TimelineEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TimelineEntryActorEnum {
  @JsonValue(r'customer')
  customer(r'customer'),
  @JsonValue(r'provider')
  provider(r'provider'),
  @JsonValue(r'system')
  system(r'system'),
  @JsonValue(r'admin')
  admin(r'admin');

  const TimelineEntryActorEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
