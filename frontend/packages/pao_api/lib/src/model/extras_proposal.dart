//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/booking_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'extras_proposal.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExtrasProposal {
  /// Returns a new [ExtrasProposal] instance.
  ExtrasProposal({
    required this.id,

    required this.items,

    required this.addedTotal,

    required this.newTotal,

    required this.status,

    required this.proposedAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<BookingItem> items;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'addedTotal', required: true, includeIfNull: false)
  final int addedTotal;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'newTotal', required: true, includeIfNull: false)
  final int newTotal;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ExtrasProposalStatusEnum status;

  @JsonKey(name: r'proposedAt', required: true, includeIfNull: false)
  final DateTime proposedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExtrasProposal &&
            runtimeType == other.runtimeType &&
            equals(
              [id, items, addedTotal, newTotal, status, proposedAt],
              [
                other.id,
                other.items,
                other.addedTotal,
                other.newTotal,
                other.status,
                other.proposedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, items, addedTotal, newTotal, status, proposedAt]);

  factory ExtrasProposal.fromJson(Map<String, dynamic> json) =>
      _$ExtrasProposalFromJson(json);

  Map<String, dynamic> toJson() => _$ExtrasProposalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ExtrasProposalStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'declined')
  declined(r'declined');

  const ExtrasProposalStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
