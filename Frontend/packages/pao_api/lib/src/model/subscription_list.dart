//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/subscription.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'subscription_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubscriptionList {
  /// Returns a new [SubscriptionList] instance.
  SubscriptionList({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<Subscription> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubscriptionList &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory SubscriptionList.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionListFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
