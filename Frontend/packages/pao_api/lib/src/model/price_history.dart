//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/price_version.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'price_history.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PriceHistory {
  /// Returns a new [PriceHistory] instance.
  PriceHistory({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<PriceVersion> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PriceHistory &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory PriceHistory.fromJson(Map<String, dynamic> json) =>
      _$PriceHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PriceHistoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
