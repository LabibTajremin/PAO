import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart' as gen show Gender;
import 'package:pao_api/pao_api.dart' hide Gender;
import 'package:pao_partner/features/enrolment/domain/step_input.dart';

/// Sends [input] to its step endpoint and returns the new progress.
Future<EnrolmentStatus> sendStep(Dio dio, StepInput input) {
  final api = ProviderEnrolmentApi(dio);
  return switch (input) {
    PersonalDetails() => _data(
      api.savePersonalStep(personalInfoInput: _personal(input)),
    ),
    PoliceClearance() => _data(
      api.savePoliceClearanceStep(
        policeClearanceInput: PoliceClearanceInput(
          mediaId: input.mediaId,
          issueDate: isoDate(input.issueDate),
        ),
      ),
    ),
    ServiceChoice() => _data(
      api.saveServicesStep(servicesInput: _services(input)),
    ),
    WorkArea() => _data(api.saveAreaStep(serviceAreaInput: _area(input))),
    NidDetails() => _data(api.saveNidStep(nidInput: _nid(input))),
    SelfiePhoto() => _data(
      api.saveSelfieStep(selfieInput: SelfieInput(mediaId: input.mediaId)),
    ),
    SkillProof() => _data(
      api.saveSkillProofStep(
        skillProofInput: SkillProofInput(mediaIds: input.mediaIds),
      ),
    ),
    EmergencyContact() => _data(
      api.saveEmergencyContactStep(emergencyContactInput: _contact(input)),
    ),
    ConductAcceptance() => _data(
      api.saveCodeOfConductStep(
        codeOfConductInput: CodeOfConductInput(
          version: input.version,
          accepted: true,
        ),
      ),
    ),
  };
}

PersonalInfoInput _personal(PersonalDetails input) => PersonalInfoInput(
  fullName: input.fullName,
  dateOfBirth: isoDate(input.dateOfBirth),
  gender: gen.Gender.values.byName(input.gender.name),
  presentAddress: input.presentAddress,
  permanentAddress: input.permanentAddress,
);

ServicesInput _services(ServiceChoice input) => ServicesInput(
  serviceIds: input.serviceIds,
  experienceYears: input.experienceYears,
);

ServiceAreaInput _area(WorkArea input) => ServiceAreaInput(
  homeBase: Point(lat: input.lat, lng: input.lng),
  workingRadiusM: input.radiusM,
);

NidInput _nid(NidDetails input) => NidInput(
  nidNumber: input.number,
  frontMediaId: input.frontId,
  backMediaId: input.backId,
);

EmergencyContactInput _contact(EmergencyContact input) => EmergencyContactInput(
  name: input.name,
  relation: input.relation,
  phone: input.phone,
);

Future<EnrolmentStatus> _data(Future<Response<EnrolmentStatus>> call) async =>
    (await call).data!;

/// A calendar date as `yyyy-MM-dd`.
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
