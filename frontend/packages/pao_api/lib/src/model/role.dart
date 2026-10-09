//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum Role {
  @JsonValue(r'customer')
  customer(r'customer'),
  @JsonValue(r'provider')
  provider(r'provider'),
  @JsonValue(r'verifier')
  verifier(r'verifier'),
  @JsonValue(r'catalog_manager')
  catalogManager(r'catalog_manager'),
  @JsonValue(r'support_agent')
  supportAgent(r'support_agent'),
  @JsonValue(r'super_admin')
  superAdmin(r'super_admin');

  const Role(this.value);

  final String value;

  @override
  String toString() => value;
}
