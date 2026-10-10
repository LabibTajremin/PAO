import 'package:pao_partner/features/enrolment/domain/enrolment.dart';

/// What one wizard step sends to the server.
sealed class StepInput {
  const StepInput();

  /// The step this saves.
  EnrolStep get step;
}

/// Gender as on the NID.
enum Gender {
  /// Female.
  female,

  /// Male.
  male,

  /// Other.
  other,
}

/// M05.
class PersonalDetails extends StepInput {
  /// Creates the input.
  const PersonalDetails({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.presentAddress,
    required this.permanentAddress,
  });

  /// Name exactly as on the NID.
  final String fullName;

  /// Calendar date of birth.
  final DateTime dateOfBirth;

  /// Gender.
  final Gender gender;

  /// Where the provider lives now.
  final String presentAddress;

  /// Home address on record.
  final String permanentAddress;

  @override
  EnrolStep get step => EnrolStep.personal;
}

/// M06.
class ServiceChoice extends StepInput {
  /// Creates the input.
  const ServiceChoice({
    required this.serviceIds,
    required this.experienceYears,
  });

  /// Chosen service IDs (1–5).
  final List<String> serviceIds;

  /// Years of experience.
  final int experienceYears;

  @override
  EnrolStep get step => EnrolStep.services;
}

/// M07.
class WorkArea extends StepInput {
  /// Creates the input.
  const WorkArea({required this.lat, required this.lng, required this.radiusM});

  /// Home base latitude.
  final double lat;

  /// Home base longitude.
  final double lng;

  /// Working radius in metres.
  final int radiusM;

  @override
  EnrolStep get step => EnrolStep.area;
}

/// M08.
class NidDetails extends StepInput {
  /// Creates the input.
  const NidDetails({
    required this.number,
    required this.frontId,
    required this.backId,
  });

  /// NID number.
  final String number;

  /// Uploaded front photo.
  final String frontId;

  /// Uploaded back photo.
  final String backId;

  @override
  EnrolStep get step => EnrolStep.nid;
}

/// M09.
class SelfiePhoto extends StepInput {
  /// Creates the input.
  const SelfiePhoto(this.mediaId);

  /// Uploaded selfie.
  final String mediaId;

  @override
  EnrolStep get step => EnrolStep.selfie;
}

/// M10.
class PoliceClearance extends StepInput {
  /// Creates the input.
  const PoliceClearance({required this.mediaId, required this.issueDate});

  /// Uploaded certificate.
  final String mediaId;

  /// Calendar date the certificate was issued.
  final DateTime issueDate;

  @override
  EnrolStep get step => EnrolStep.policeClearance;
}

/// M11.
class SkillProof extends StepInput {
  /// Creates the input.
  const SkillProof(this.mediaIds);

  /// Uploaded certificates or work photos.
  final List<String> mediaIds;

  @override
  EnrolStep get step => EnrolStep.skillProof;
}

/// M12; saving it texts a code to the contact.
class EmergencyContact extends StepInput {
  /// Creates the input.
  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  /// Contact's name.
  final String name;

  /// How they are related.
  final String relation;

  /// Their mobile number.
  final String phone;

  @override
  EnrolStep get step => EnrolStep.emergencyContact;
}

/// M13.
class ConductAcceptance extends StepInput {
  /// Creates the input for [version].
  const ConductAcceptance([this.version = conductVersion]);

  /// Accepted text version.
  final String version;

  @override
  EnrolStep get step => EnrolStep.codeOfConduct;
}
