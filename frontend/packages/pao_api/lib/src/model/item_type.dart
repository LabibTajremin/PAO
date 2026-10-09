//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ItemType {
  @JsonValue(r'nid')
  nid(r'nid'),
  @JsonValue(r'selfie')
  selfie(r'selfie'),
  @JsonValue(r'police_clearance')
  policeClearance(r'police_clearance'),
  @JsonValue(r'address')
  address(r'address'),
  @JsonValue(r'emergency_contact')
  emergencyContact(r'emergency_contact'),
  @JsonValue(r'skill_proof')
  skillProof(r'skill_proof'),
  @JsonValue(r'service_area')
  serviceArea(r'service_area'),
  @JsonValue(r'code_of_conduct')
  codeOfConduct(r'code_of_conduct');

  const ItemType(this.value);

  final String value;

  @override
  String toString() => value;
}
