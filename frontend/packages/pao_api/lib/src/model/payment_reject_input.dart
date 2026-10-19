//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_reject_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentRejectInput {
  /// Returns a new [PaymentRejectInput] instance.
  PaymentRejectInput({required this.reason});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentRejectInput &&
            runtimeType == other.runtimeType &&
            equals([reason], [other.reason]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([reason]);

  factory PaymentRejectInput.fromJson(Map<String, dynamic> json) =>
      _$PaymentRejectInputFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentRejectInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
