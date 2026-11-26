//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'delivery_window.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeliveryWindow {
  /// Returns a new [DeliveryWindow] instance.
  DeliveryWindow({required this.start, required this.end});

  @JsonKey(name: r'start', required: true, includeIfNull: false)
  final String start;

  @JsonKey(name: r'end', required: true, includeIfNull: false)
  final String end;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeliveryWindow &&
            runtimeType == other.runtimeType &&
            equals([start, end], [other.start, other.end]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([start, end]);

  factory DeliveryWindow.fromJson(Map<String, dynamic> json) =>
      _$DeliveryWindowFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryWindowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
