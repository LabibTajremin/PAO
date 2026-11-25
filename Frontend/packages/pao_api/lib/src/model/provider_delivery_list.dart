//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/provider_delivery.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'provider_delivery_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderDeliveryList {
  /// Returns a new [ProviderDeliveryList] instance.
  ProviderDeliveryList({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ProviderDelivery> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProviderDeliveryList &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory ProviderDeliveryList.fromJson(Map<String, dynamic> json) =>
      _$ProviderDeliveryListFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderDeliveryListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
