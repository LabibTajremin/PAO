//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'provider_cancel_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderCancelInput {
  /// Returns a new [ProviderCancelInput] instance.
  ProviderCancelInput({required this.reason, this.note});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final ProviderCancelInputReasonEnum reason;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProviderCancelInput &&
            runtimeType == other.runtimeType &&
            equals([reason, note], [other.reason, other.note]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([reason, note]);

  factory ProviderCancelInput.fromJson(Map<String, dynamic> json) =>
      _$ProviderCancelInputFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderCancelInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProviderCancelInputReasonEnum {
  @JsonValue(r'emergency')
  emergency(r'emergency'),
  @JsonValue(r'customer_unreachable')
  customerUnreachable(r'customer_unreachable'),
  @JsonValue(r'unsafe_location')
  unsafeLocation(r'unsafe_location'),
  @JsonValue(r'other')
  other(r'other');

  const ProviderCancelInputReasonEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
