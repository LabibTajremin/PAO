import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment.dart';
import 'package:pao_partner/features/enrolment/domain/enrolment_repository.dart';
import 'package:pao_partner/features/enrolment/domain/step_input.dart';

/// The wizard (M05–M13).
class EnrolState {
  /// Creates the state.
  const EnrolState({
    this.view = const ViewLoading(),
    this.step,
    this.saving = false,
    this.failure,
    this.codeSent = false,
    this.finished = false,
  });

  /// Progress from the server.
  final ViewState<EnrolProgress> view;

  /// The step on screen; null shows the review before submitting.
  final EnrolStep? step;

  /// A save is in flight.
  final bool saving;

  /// Why the last action failed.
  final AppFailure? failure;

  /// The emergency contact was texted a code.
  final bool codeSent;

  /// Submitted; the page moves on to verification.
  final bool finished;

  /// Loaded progress, or null.
  EnrolProgress? get progress => switch (view) {
    ViewData(:final data) => data,
    _ => null,
  };

  /// A copy on [step] with the action state cleared.
  EnrolState on(EnrolStep? step, {EnrolProgress? progress}) => EnrolState(
    view: progress == null ? view : ViewData(progress),
    step: step,
  );
}

/// Loads progress, saves steps in order and submits.
class EnrolmentCubit extends Cubit<EnrolState> {
  /// Creates the cubit; [onFinished] reloads the verification gate.
  EnrolmentCubit(this._repo, {required this.onFinished})
    : super(const EnrolState());

  final EnrolmentRepository _repo;

  /// Runs once the enrolment is with the verifiers.
  final Future<void> Function() onFinished;

  /// Loads progress and opens [requested], or the first step still to do.
  Future<void> load(String requested) async {
    emit(const EnrolState());
    try {
      final p = await _repo.progress();
      emit(EnrolState(view: ViewData(p)).on(_opening(requested, p)));
    } on Object catch (e) {
      emit(EnrolState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  EnrolStep? _opening(String requested, EnrolProgress p) =>
      EnrolStep.parse(requested) ?? p.firstIncomplete;

  /// Saves the current step and moves on; the emergency contact waits for
  /// its code first.
  Future<void> save(StepInput input) => _run(() async {
    final p = await _repo.save(input);
    if (input is! EmergencyContact) return await _advance(p);
    return EnrolState(view: ViewData(p), step: state.step, codeSent: true);
  });

  /// Confirms the emergency contact's code.
  Future<void> verifyCode(String code) =>
      _run(() async => await _advance(await _repo.verifyContact(code)));

  /// Sends the enrolment for verification.
  Future<void> submit() => _run(() async {
    await _repo.submit();
    await onFinished();
    return const EnrolState(finished: true);
  });

  /// Leaves an optional step without saving.
  void skip() => emit(state.on(state.progress!.nextAfter(state.step!)));

  /// Shows [step]; null is the review.
  void open(EnrolStep? step) => emit(state.on(step));

  /// Back to the previous step.
  void back() {
    final i = state.step?.index ?? EnrolStep.values.length;
    if (i > 0) open(EnrolStep.values[i - 1]);
  }

  /// Lets the provider change the emergency contact after a code was sent.
  void editContact() => emit(state.on(state.step));

  // Saves can finish after the page is gone.
  @override
  void emit(EnrolState state) {
    if (!isClosed) super.emit(state);
  }

  Future<EnrolState> _advance(EnrolProgress p) async {
    // Re-uploads after submission go straight back into review on the server,
    // so only a required gap keeps the provider in the wizard.
    final next = p.submitted ? p.firstIncomplete : p.nextAfter(state.step!);
    if (next == null && p.submitted) {
      await onFinished();
      return const EnrolState(finished: true);
    }
    return state.on(next, progress: p);
  }

  Future<void> _run(Future<EnrolState> Function() action) async {
    emit(
      EnrolState(
        view: state.view,
        step: state.step,
        saving: true,
        codeSent: state.codeSent,
      ),
    );
    try {
      emit(await action());
    } on Object catch (e) {
      emit(
        EnrolState(
          view: state.view,
          step: state.step,
          failure: AppFailure.from(e),
          codeSent: state.codeSent,
        ),
      );
    }
  }
}
