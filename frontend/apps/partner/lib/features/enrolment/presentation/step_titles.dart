import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/l10n/generated/partner_localizations.dart';

/// The heading of [step].
String stepTitle(PartnerL10n t, EnrolStep step) => switch (step) {
  EnrolStep.personal => t.enrolStepPersonal,
  EnrolStep.services => t.enrolStepServices,
  EnrolStep.area => t.enrolStepArea,
  EnrolStep.nid => t.enrolStepNid,
  EnrolStep.selfie => t.enrolStepSelfie,
  EnrolStep.policeClearance => t.enrolStepPolice,
  EnrolStep.skillProof => t.enrolStepSkill,
  EnrolStep.emergencyContact => t.enrolStepContact,
  EnrolStep.codeOfConduct => t.enrolStepConduct,
};
