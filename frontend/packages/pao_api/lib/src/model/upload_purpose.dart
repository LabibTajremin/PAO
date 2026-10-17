//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum UploadPurpose {
  @JsonValue(r'avatar')
  avatar(r'avatar'),
  @JsonValue(r'nid_front')
  nidFront(r'nid_front'),
  @JsonValue(r'nid_back')
  nidBack(r'nid_back'),
  @JsonValue(r'selfie')
  selfie(r'selfie'),
  @JsonValue(r'police_clearance')
  policeClearance(r'police_clearance'),
  @JsonValue(r'skill_proof')
  skillProof(r'skill_proof'),
  @JsonValue(r'address_proof')
  addressProof(r'address_proof'),
  @JsonValue(r'complaint_photo')
  complaintPhoto(r'complaint_photo'),
  @JsonValue(r'level2_photo')
  level2Photo(r'level2_photo');

  const UploadPurpose(this.value);

  final String value;

  @override
  String toString() => value;
}
