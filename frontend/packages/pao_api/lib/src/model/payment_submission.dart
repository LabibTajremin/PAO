//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/payment_submission_status.dart';
import 'package:pao_api/src/model/payment_method_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_submission.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentSubmission {
  /// Returns a new [PaymentSubmission] instance.
  PaymentSubmission({
    required this.id,

    required this.providerId,

    required this.amount,

    required this.method,

    required this.reference,

    required this.status,

    this.reviewerId,

    this.reason,

    required this.createdAt,

    this.reviewedAt,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'providerId', required: true, includeIfNull: false)
  final String providerId;

  /// Amount in paisa (1 BDT = 100 paisa). Never a float (04-decisions.md E9).
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'method', required: true, includeIfNull: false)
  final PaymentMethodKind method;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final PaymentSubmissionStatus status;

  @JsonKey(name: r'reviewerId', required: false, includeIfNull: false)
  final String? reviewerId;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'reviewedAt', required: false, includeIfNull: false)
  final DateTime? reviewedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentSubmission &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                providerId,
                amount,
                method,
                reference,
                status,
                reviewerId,
                reason,
                createdAt,
                reviewedAt,
              ],
              [
                other.id,
                other.providerId,
                other.amount,
                other.method,
                other.reference,
                other.status,
                other.reviewerId,
                other.reason,
                other.createdAt,
                other.reviewedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        providerId,
        amount,
        method,
        reference,
        status,
        reviewerId,
        reason,
        createdAt,
        reviewedAt,
      ]);

  factory PaymentSubmission.fromJson(Map<String, dynamic> json) =>
      _$PaymentSubmissionFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSubmissionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
