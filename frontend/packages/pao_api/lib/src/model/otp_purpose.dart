//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// Why the code is sent. `delete_account` re-confirms account deletion.
enum OtpPurpose {
  /// Why the code is sent. `delete_account` re-confirms account deletion.
  @JsonValue(r'login')
  login(r'login'),

  /// Why the code is sent. `delete_account` re-confirms account deletion.
  @JsonValue(r'delete_account')
  deleteAccount(r'delete_account');

  const OtpPurpose(this.value);

  final String value;

  @override
  String toString() => value;
}
