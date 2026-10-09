//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_cancel_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerCancelInput {
  /// Returns a new [CustomerCancelInput] instance.
  CustomerCancelInput({required this.reason, this.note});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final CustomerCancelInputReasonEnum reason;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerCancelInput &&
            runtimeType == other.runtimeType &&
            equals([reason, note], [other.reason, other.note]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([reason, note]);

  factory CustomerCancelInput.fromJson(Map<String, dynamic> json) =>
      _$CustomerCancelInputFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerCancelInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CustomerCancelInputReasonEnum {
  @JsonValue(r'changed_mind')
  changedMind(r'changed_mind'),
  @JsonValue(r'found_other_provider')
  foundOtherProvider(r'found_other_provider'),
  @JsonValue(r'provider_late')
  providerLate(r'provider_late'),
  @JsonValue(r'booked_by_mistake')
  bookedByMistake(r'booked_by_mistake'),
  @JsonValue(r'other')
  other(r'other');

  const CustomerCancelInputReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
