//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'upload_ticket.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadTicket {
  /// Returns a new [UploadTicket] instance.
  UploadTicket({
    required this.mediaId,

    required this.uploadUrl,

    required this.headers,

    required this.expiresAt,
  });

  @JsonKey(name: r'mediaId', required: true, includeIfNull: false)
  final String mediaId;

  @JsonKey(name: r'uploadUrl', required: true, includeIfNull: false)
  final String uploadUrl;

  @JsonKey(name: r'headers', required: true, includeIfNull: false)
  final Map<String, String> headers;

  @JsonKey(name: r'expiresAt', required: true, includeIfNull: false)
  final DateTime expiresAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UploadTicket &&
            runtimeType == other.runtimeType &&
            equals(
              [mediaId, uploadUrl, headers, expiresAt],
              [other.mediaId, other.uploadUrl, other.headers, other.expiresAt],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([mediaId, uploadUrl, headers, expiresAt]);

  factory UploadTicket.fromJson(Map<String, dynamic> json) =>
      _$UploadTicketFromJson(json);

  Map<String, dynamic> toJson() => _$UploadTicketToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
