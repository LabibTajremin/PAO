//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/payment_method_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_submission_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentSubmissionInput {
  /// Returns a new [PaymentSubmissionInput] instance.
  PaymentSubmissionInput({
    required this.amountPaisa,

    required this.method,

    required this.reference,
  });

  // minimum: 1
  // maximum: 100000000
  @JsonKey(name: r'amountPaisa', required: true, includeIfNull: false)
  final int amountPaisa;

  @JsonKey(name: r'method', required: true, includeIfNull: false)
  final PaymentMethodKind method;

  /// Transaction id, receipt number or agent name.
  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentSubmissionInput &&
            runtimeType == other.runtimeType &&
            equals(
              [amountPaisa, method, reference],
              [other.amountPaisa, other.method, other.reference],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([amountPaisa, method, reference]);

  factory PaymentSubmissionInput.fromJson(Map<String, dynamic> json) =>
      _$PaymentSubmissionInputFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSubmissionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
