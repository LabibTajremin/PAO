//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'price_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PriceInput {
  /// Returns a new [PriceInput] instance.
  PriceInput({required this.amount});

  // minimum: 0
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PriceInput &&
            runtimeType == other.runtimeType &&
            equals([amount], [other.amount]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([amount]);

  factory PriceInput.fromJson(Map<String, dynamic> json) =>
      _$PriceInputFromJson(json);

  Map<String, dynamic> toJson() => _$PriceInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
