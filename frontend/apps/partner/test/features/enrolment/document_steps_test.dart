import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/nid_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/police_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/review_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/selfie_step.dart';
import 'package:pao_partner/features/enrolment/presentation/steps/skill_step.dart';

import 'fakes.dart';

void main() {
  late FakeEnrolmentRepository repo;

  setUp(() => repo = FakeEnrolmentRepository());

  Future<void> save(WidgetTester tester) async {
    await tapIn(tester, find.text('Save and continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('NID: number, both photos with progress and retry', (
    tester,
  ) async {
    await pumpStep(tester, const NidStep(), repo: repo);
    await save(tester);
    expect(find.text('Enter the 10, 13 or 17-digit NID number.'), findsOne);
    expect(find.text('Add every photo before you continue.'), findsOne);
    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.tap(find.text('Take photo').first);
    await tester.pump();
    expect(find.text('Uploading 0%'), findsOne);
    repo.progressOf.single!(0.4);
    await tester.pump();
    expect(find.text('Uploading 40%'), findsOne);
    repo.uploads.single.complete('front');
    await tester.pumpAndSettle();
    expect(find.text('Uploaded'), findsOne);
    expect(find.text('Retake'), findsOne);
    await tapIn(tester, find.text('Take photo'));
    await tester.pump();
    repo.uploads.last.completeError(const NetworkFailure());
    await tester.pumpAndSettle();
    expect(find.textContaining('Upload failed.'), findsOne);
    await tapIn(tester, find.text('Try again'));
    await tester.pump();
    repo.uploads.last.complete('back');
    await tester.pumpAndSettle();
    await save(tester);
    final nid = repo.saved.single as NidDetails;
    expect(
      [nid.number, nid.frontId, nid.backId],
      ['1234567890', 'front', 'back'],
    );
  });

  testWidgets('selfie: front camera only, saved once uploaded', (tester) async {
    final modes = <PhotoMode>[];
    await pumpStep(
      tester,
      const SelfieStep(),
      repo: repo,
      open: EnrolStep.selfie,
      capture: (mode) async {
        modes.add(mode);
        return tinyPng;
      },
    );
    await save(tester);
    expect(repo.saved, isEmpty);
    await tester.tap(find.text('Take photo'));
    await tester.pump();
    repo.uploads.single.complete('face');
    await tester.pumpAndSettle();
    await save(tester);
    expect(modes, [PhotoMode.selfie]);
    expect((repo.saved.single as SelfiePhoto).mediaId, 'face');
  });

  testWidgets('police clearance: gallery photo and issue date', (tester) async {
    final (enrol, _) = await pumpStep(
      tester,
      PoliceStep(today: DateTime(2026, 10, 9)),
      repo: repo,
      open: EnrolStep.policeClearance,
    );
    await save(tester);
    expect(find.text('Enter the issue date.'), findsOne);
    expect(find.text('Add every photo before you continue.'), findsOne);
    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    repo.uploads.single.complete('cert');
    await tester.pumpAndSettle();
    await tapIn(tester, find.text('Select a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Oct 9, 2026'), findsOne);
    repo.fail = const NetworkFailure();
    await save(tester);
    expect(enrol.state.failure!.code, 'NETWORK');
    expect(find.textContaining('internet'), findsOne);
    repo.fail = null;
    await save(tester);
    final saved = repo.saved.single as PoliceClearance;
    expect([saved.mediaId, saved.issueDate], ['cert', DateTime(2026, 10, 9)]);
  });

  testWidgets('skill proof: optional photos, skip or save', (tester) async {
    final (enrol, uploads) = await pumpStep(
      tester,
      const SkillStep(),
      repo: repo,
      open: EnrolStep.skillProof,
    );
    await tester.tap(find.text('Take photo'));
    await tester.pump();
    repo.uploads.single.complete('w1');
    await tester.pumpAndSettle();
    expect(find.text('Photo 1'), findsOne);
    await tapIn(tester, find.text('Choose from gallery').last);
    await tester.pump();
    repo.uploads.last.complete('w2');
    await tester.pumpAndSettle();
    expect(uploads.mediaIds('skill_proof'), ['w1', 'w2']);
    await save(tester);
    expect((repo.saved.single as SkillProof).mediaIds, ['w1', 'w2']);
    enrol.open(EnrolStep.skillProof);
    await tester.pumpAndSettle();
    await tapIn(tester, find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(enrol.state.step, EnrolStep.emergencyContact);
  });

  testWidgets('the review marks missing required steps', (tester) async {
    final progress = progressWith(done: {EnrolStep.personal});
    await pumpStep(
      tester,
      ReviewStep(progress: progress),
      repo: repo,
      open: EnrolStep.personal,
    );
    expect(find.text('Done'), findsOne);
    expect(find.text('To do'), findsWidgets);
  });
}
