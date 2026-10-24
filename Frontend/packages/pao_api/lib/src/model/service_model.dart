//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ServiceModel {
  @JsonValue(r'on_demand')
  onDemand(r'on_demand'),
  @JsonValue(r'duration_hire')
  durationHire(r'duration_hire'),
  @JsonValue(r'listing')
  listing(r'listing'),
  @JsonValue(r'partner_referral')
  partnerReferral(r'partner_referral');

  const ServiceModel(this.value);

  final String value;

  @override
  String toString() => value;
}
