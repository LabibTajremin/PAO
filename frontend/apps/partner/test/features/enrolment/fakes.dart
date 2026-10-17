import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment_repository.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';
import 'package:pao_partner/features/enrolment/presentation/enrolment_cubit.dart';
import 'package:pao_partner/features/enrolment/presentation/uploads_cubit.dart';

import '../../support/harness.dart';

/// A 1×1 PNG, small enough to inline and real enough to decode.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwAD'
  'hgGAWjR9awAAAABJRU5ErkJggg==',
);

/// The API's enrolment status with [done] steps saved.
Map<String, Object?> enrolmentJson({
  Set<EnrolStep> done = const {},
  bool submitted = false,
}) => {
  'steps': [
    for (final s in EnrolStep.values)
      {
        'step': s.key,
        'done': done.contains(s),
        'required': s != EnrolStep.skillProof,
      },
  ],
  'complete': EnrolStep.values.every(
    (s) => s == EnrolStep.skillProof || done.contains(s),
  ),
  'submitted': submitted,
};

/// Progress with [done] steps saved.
EnrolProgress progressWith({
  Set<EnrolStep> done = const {},
  bool submitted = false,
}) => EnrolProgress(
  steps: [
    for (final s in EnrolStep.values)
      StepProgress(
        s,
        done: done.contains(s),
        required: s != EnrolStep.skillProof,
      ),
  ],
  complete: EnrolStep.values.every(
    (s) => s == EnrolStep.skillProof || done.contains(s),
  ),
  submitted: submitted,
);

/// Every required step.
final Set<EnrolStep> allRequired = {
  for (final s in EnrolStep.values)
    if (s != EnrolStep.skillProof) s,
};

/// Hand-written [EnrolmentRepository] the tests drive.
class FakeEnrolmentRepository implements EnrolmentRepository {
  /// What [progress] returns.
  EnrolProgress current = progressWith();

  /// Thrown by the next call when set.
  Exception? fail;

  /// Saved inputs.
  final saved = <StepInput>[];

  /// Codes checked.
  final codes = <String>[];

  /// Services offered.
  List<ServiceOption> options = const [
    ServiceOption(id: 's1', en: 'Electrician', bn: 'ইলেকট্রিশিয়ান'),
    ServiceOption(id: 's2', en: 'Plumber', bn: 'প্লাম্বার'),
  ];

  /// Pending uploads, completed by the test.
  final uploads = <Completer<String>>[];

  /// Progress callbacks of [uploads].
  final progressOf = <void Function(double)?>[];

  /// Submissions.
  int submits = 0;

  void _check() {
    final f = fail;
    if (f != null) throw f;
  }

  @override
  Future<EnrolProgress> progress() async {
    _check();
    return current;
  }

  @override
  Future<List<ServiceOption>> serviceOptions() async {
    _check();
    return options;
  }

  @override
  Future<EnrolProgress> save(StepInput input) async {
    _check();
    saved.add(input);
    final done = {
      for (final s in current.steps)
        if (s.done) s.step,
      if (input is! EmergencyContact) input.step,
    };
    return current = progressWith(done: done, submitted: current.submitted);
  }

  @override
  Future<EnrolProgress> verifyContact(String code) async {
    _check();
    codes.add(code);
    final done = {
      for (final s in current.steps)
        if (s.done) s.step,
      EnrolStep.emergencyContact,
    };
    return current = progressWith(done: done, submitted: current.submitted);
  }

  @override
  Future<String> upload(
    Uint8List bytes,
    String purpose, {
    void Function(double progress)? onProgress,
  }) {
    final c = Completer<String>();
    uploads.add(c);
    progressOf.add(onProgress);
    return c.future;
  }

  @override
  Future<void> submit() async {
    _check();
    submits++;
  }
}

/// Pumps [step] with cubits over [repo]; [capture] stands in for the camera.
Future<(EnrolmentCubit, UploadsCubit)> pumpStep(
  WidgetTester tester,
  Widget step, {
  required FakeEnrolmentRepository repo,
  Capture? capture,
  EnrolStep open = EnrolStep.nid,
}) async {
  final enrol = EnrolmentCubit(repo, onFinished: () async {});
  await enrol.load(open.key);
  final uploads = UploadsCubit(repo, capture ?? (_) async => tinyPng);
  await pumpPage(
    tester,
    RepositoryProvider<EnrolmentRepository>.value(
      value: repo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: enrol),
          BlocProvider.value(value: uploads),
        ],
        child: Scaffold(body: step),
      ),
    ),
  );
  addTearDown(enrol.close);
  addTearDown(uploads.close);
  return (enrol, uploads);
}

/// Brings [finder] into view, scrolling the first list if it is not built
/// yet, and taps its first match.
Future<void> tapIn(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
}

/// An API error reply body.
Map<String, Object?> apiError(String code) => {
  'error': {'code': code, 'message': 'x'},
};

/// Failure for fakes.
const offline = NetworkFailure();
