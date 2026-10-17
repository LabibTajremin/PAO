//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum EnrolmentStep {
  @JsonValue(r'personal')
  personal(r'personal'),
  @JsonValue(r'services')
  services(r'services'),
  @JsonValue(r'area')
  area(r'area'),
  @JsonValue(r'nid')
  nid(r'nid'),
  @JsonValue(r'selfie')
  selfie(r'selfie'),
  @JsonValue(r'police_clearance')
  policeClearance(r'police_clearance'),
  @JsonValue(r'skill_proof')
  skillProof(r'skill_proof'),
  @JsonValue(r'emergency_contact')
  emergencyContact(r'emergency_contact'),
  @JsonValue(r'code_of_conduct')
  codeOfConduct(r'code_of_conduct');

  const EnrolmentStep(this.value);

  final String value;

  @override
  String toString() => value;
}
