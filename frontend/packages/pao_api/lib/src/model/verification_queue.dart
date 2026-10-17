//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/verification_queue_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verification_queue.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerificationQueue {
  /// Returns a new [VerificationQueue] instance.
  VerificationQueue({required this.items, this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<VerificationQueueItem> items;

  /// Opaque cursor for the next page (base64 of created_at and id).
  @JsonKey(name: r'nextCursor', required: false, includeIfNull: false)
  final String? nextCursor;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerificationQueue &&
            runtimeType == other.runtimeType &&
            equals([items, nextCursor], [other.items, other.nextCursor]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([items, nextCursor]);

  factory VerificationQueue.fromJson(Map<String, dynamic> json) =>
      _$VerificationQueueFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationQueueToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
