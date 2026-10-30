import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/uploads_cubit.dart';

import 'fakes.dart';

void main() {
  late FakeEnrolmentRepository repo;
  late int finished;
  late EnrolmentCubit cubit;

  setUp(() {
    repo = FakeEnrolmentRepository();
    finished = 0;
    cubit = EnrolmentCubit(repo, onFinished: () async => finished++);
  });

  test('loads the requested step or resumes at the first gap', () async {
    repo.current = progressWith(done: {EnrolStep.personal});
    await cubit.load('nid');
    expect(cubit.state.step, EnrolStep.nid);
    await cubit.load('anything');
    expect(cubit.state.step, EnrolStep.services);
    repo.fail = offline;
    await cubit.load('nid');
    expect(cubit.state.view, isA<ViewFailure<EnrolProgress>>());
    expect(cubit.state.progress, isNull);
  });

  test('saving moves on; failures stay on the step', () async {
    await cubit.load(EnrolStep.policeClearance.key);
    repo.fail = offline;
    await cubit.save(PoliceClearance(mediaId: 'p', issueDate: DateTime(2026)));
    expect(
      [cubit.state.step, cubit.state.failure!.code],
      [EnrolStep.policeClearance, 'NETWORK'],
    );
    repo.fail = null;
    await cubit.save(PoliceClearance(mediaId: 'p', issueDate: DateTime(2026)));
    expect(
      [cubit.state.step, cubit.state.failure],
      [EnrolStep.skillProof, null],
    );
    cubit.skip();
    expect(cubit.state.step, EnrolStep.emergencyContact);
  });

  test('the emergency contact waits for its code', () async {
    await cubit.load(EnrolStep.emergencyContact.key);
    const contact = EmergencyContact(name: 'K', relation: 'B', phone: '0');
    await cubit.save(contact);
    expect(
      [cubit.state.step, cubit.state.codeSent],
      [EnrolStep.emergencyContact, true],
    );
    repo.fail = const ApiFailure('OTP_INVALID', status: 422);
    await cubit.verifyCode('000000');
    expect(
      [cubit.state.codeSent, cubit.state.failure!.code],
      [true, 'OTP_INVALID'],
    );
    cubit.editContact();
    expect(cubit.state.codeSent, isFalse);
    repo.fail = null;
    await cubit.save(contact);
    await cubit.verifyCode('123456');
    expect(
      [cubit.state.step, repo.codes],
      [
        EnrolStep.codeOfConduct,
        ['123456'],
      ],
    );
  });

  test('the last step leads to the review, then submission', () async {
    repo.current = progressWith(
      done: allRequired.difference({EnrolStep.codeOfConduct}),
    );
    await cubit.load(EnrolStep.codeOfConduct.key);
    await cubit.save(const ConductAcceptance());
    expect(cubit.state.step, isNull);
    cubit.back();
    expect(cubit.state.step, EnrolStep.codeOfConduct);
    cubit.open(null);
    await cubit.submit();
    expect([cubit.state.finished, repo.submits, finished], [true, 1, 1]);
  });

  test('a re-upload after submission finishes straight away', () async {
    repo.current = progressWith(done: allRequired, submitted: true);
    await cubit.load(EnrolStep.selfie.key);
    await cubit.save(const SelfiePhoto('s'));
    expect([cubit.state.finished, finished], [true, 1]);
  });

  test('back stops at the first step; a closed cubit ignores saves', () async {
    await cubit.load(EnrolStep.personal.key);
    cubit.back();
    expect(cubit.state.step, EnrolStep.personal);
    final save = cubit.save(const SelfiePhoto('s'));
    await cubit.close();
    await save;
  });

  group('uploads', () {
    test('capture uploads with progress; cancel does nothing', () async {
      final uploads = UploadsCubit(repo, (_) async => tinyPng);
      final done = uploads.capture('skill_proof:0', PhotoMode.camera);
      await Future<void>.delayed(Duration.zero);
      expect(uploads.state['skill_proof:0']!.uploading, isTrue);
      repo.progressOf.single!(0.5);
      expect(uploads.state['skill_proof:0']!.progress, 0.5);
      repo.uploads.single.complete('m1');
      await done;
      expect(uploads.mediaId('skill_proof:0'), 'm1');
      expect(uploads.mediaIds('skill_proof'), ['m1']);
      expect(uploads.slots('skill_proof'), ['skill_proof:0']);
      await UploadsCubit(
        repo,
        (_) async => null,
      ).capture('x', PhotoMode.camera);
      await uploads.close();
    });

    test('failed captures and uploads can be retried', () async {
      final broken = UploadsCubit(repo, (_) async => throw Exception('cam'));
      await broken.capture('selfie', PhotoMode.selfie);
      expect(broken.state['selfie']!.failure!.code, 'UNEXPECTED');
      final uploads = UploadsCubit(repo, (_) async => tinyPng);
      final first = uploads.capture('selfie', PhotoMode.selfie);
      await Future<void>.delayed(Duration.zero);
      repo.uploads.last.completeError(offline);
      await first;
      expect(uploads.state['selfie']!.failure!.code, 'NETWORK');
      expect(uploads.mediaIds('selfie'), isEmpty);
      final again = uploads.retry('selfie');
      await Future<void>.delayed(Duration.zero);
      final pending = repo.uploads.last;
      await uploads.close();
      pending.complete('late');
      await again;
    });
  });
}
