import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/job/domain/job_repository.dart';

/// One job and the action in flight (M17, M18, M20).
class JobState {
  /// Creates the state.
  const JobState({
    this.view = const ViewLoading(),
    this.busy = false,
    this.failure,
    this.done = false,
  });

  /// The job as last loaded or returned by an action.
  final ViewState<Booking> view;

  /// An action is in flight.
  final bool busy;

  /// Why the last action failed.
  final AppFailure? failure;

  /// The last action succeeded; pages that end with it move on.
  final bool done;

  /// The loaded job, if any.
  Booking? get booking => switch (view) {
    ViewData(:final data) => data,
    _ => null,
  };
}

/// Loads a job and runs the provider's status actions on it.
class JobCubit extends Cubit<JobState> {
  /// Creates the cubit for booking [_id]; call [load] to start.
  JobCubit(this._repo, this._id) : super(const JobState());

  final JobRepository _repo;
  final String _id;

  /// Loads the job, showing loading first.
  Future<void> load() async {
    emit(const JobState());
    await refresh();
  }

  /// Reloads without the loading state, e.g. after another screen acted.
  Future<void> refresh() async {
    final view = await _fetch();
    if (!isClosed) emit(JobState(view: view));
  }

  Future<ViewState<Booking>> _fetch() async {
    try {
      return ViewData(await _repo.job(_id));
    } on Object catch (e) {
      return ViewFailure(AppFailure.from(e));
    }
  }

  /// Moves an accepted job on the way, and a job on the way to arrived.
  Future<void> advance() => _run(
    () => state.booking?.status == BookingStatus.accepted
        ? _repo.onTheWay(_id)
        : _repo.arrived(_id),
  );

  /// Cancels the job with [reason].
  Future<void> cancel(ProviderCancelInputReasonEnum reason, String? note) =>
      _run(() => _repo.cancel(_id, reason, note));

  /// Starts the job with the customer's [code].
  Future<void> start(String code) => _run(() => _repo.start(_id, code));

  /// Completes the job with the cash received.
  Future<void> complete() => _run(() => _repo.complete(_id));

  Future<void> _run(Future<Booking> Function() action) async {
    emit(JobState(view: state.view, busy: true));
    try {
      final booking = await action();
      if (!isClosed) emit(JobState(view: ViewData(booking), done: true));
    } on Object catch (e) {
      if (!isClosed) {
        emit(JobState(view: state.view, failure: AppFailure.from(e)));
      }
    }
  }
}
