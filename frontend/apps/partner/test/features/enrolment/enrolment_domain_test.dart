import 'package:flutter_test/flutter_test.dart';
import 'package:pao_partner/features/enrolment/data/step_requests.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';

import 'fakes.dart';

void main() {
  test('steps parse from their API names', () {
    for (final step in EnrolStep.values) {
      expect(EnrolStep.parse(step.key), step);
    }
    expect(EnrolStep.parse('review'), isNull);
  });

  test('progress resumes at the first required gap', () {
    expect(progressWith().firstIncomplete, EnrolStep.personal);
    final p = progressWith(done: {EnrolStep.personal, EnrolStep.services});
    expect(p.firstIncomplete, EnrolStep.area);
    expect(p.isDone(EnrolStep.services), isTrue);
    expect(progressWith(done: allRequired).firstIncomplete, isNull);
  });

  test('the next step offers optional skill proof, then fills gaps', () {
    final p = progressWith(
      done: {EnrolStep.personal, EnrolStep.policeClearance},
    );
    expect(p.nextAfter(EnrolStep.policeClearance), EnrolStep.skillProof);
    expect(p.nextAfter(EnrolStep.personal), EnrolStep.services);
    final late = progressWith(done: allRequired.difference({EnrolStep.area}));
    expect(late.nextAfter(EnrolStep.codeOfConduct), EnrolStep.area);
    expect(
      progressWith(done: allRequired).nextAfter(EnrolStep.codeOfConduct),
      isNull,
    );
  });

  test('age, NID and dates follow the backend rules', () {
    final today = DateTime(2026, 10, 9);
    expect(isAdult(DateTime(2008, 10, 9), today), isTrue);
    expect(isAdult(DateTime(2008, 10, 10), today), isFalse);
    for (final n in ['1234567890', '1234567890123', '12345678901234567']) {
      expect(validNid(n), isTrue, reason: n);
    }
    for (final n in ['', '123456789', '12345678901', '12345abcde']) {
      expect(validNid(n), isFalse, reason: n);
    }
    expect(dhakaToday(DateTime.utc(2026, 10, 9, 19)), DateTime(2026, 10, 10));
    expect(isoDate(DateTime(990, 4, 2)), '0990-04-02');
  });

  test('service names follow the language; inputs name their step', () {
    const o = ServiceOption(id: 'a', en: 'Plumber', bn: 'প্লাম্বার');
    expect([o.name('en'), o.name('bn')], ['Plumber', 'প্লাম্বার']);
    final inputs = <StepInput>[
      PersonalDetails(
        fullName: 'Rahim',
        dateOfBirth: DateTime(1990),
        gender: Gender.male,
        presentAddress: 'Banani',
        permanentAddress: 'Bogura',
      ),
      const ServiceChoice(serviceIds: ['a'], experienceYears: 2),
      const WorkArea(lat: 1, lng: 2, radiusM: 3000),
      const NidDetails(number: '1234567890', frontId: 'f', backId: 'b'),
      const SelfiePhoto('s'),
      PoliceClearance(mediaId: 'p', issueDate: DateTime(2026)),
      const SkillProof(['k']),
      const EmergencyContact(name: 'Karim', relation: 'Brother', phone: '0'),
      const ConductAcceptance(),
    ];
    expect([for (final i in inputs) i.step], EnrolStep.values);
  });
}
