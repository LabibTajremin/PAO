//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pao_api/src/model/address.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'address_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddressList {
  /// Returns a new [AddressList] instance.
  AddressList({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<Address> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AddressList &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory AddressList.fromJson(Map<String, dynamic> json) =>
      _$AddressListFromJson(json);

  Map<String, dynamic> toJson() => _$AddressListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
