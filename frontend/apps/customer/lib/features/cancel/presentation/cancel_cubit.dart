import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/cancel/domain/cancel_repository.dart';

/// Where cancelling ended.
enum CancelOutcome {
  /// Cancelled, free of charge (C53).
  cancelled,

  /// The job has started, so it cannot be cancelled (C54).
  blocked,

  /// The provider declined or never answered; nothing is left to cancel.
  closed,
}

/// The cancel screen (C52).
class CancelState {
  /// Creates the state.
  const CancelState({
    this.view = const ViewLoading(),
    this.reason,
    this.busy = false,
    this.failure,
    this.outcome,
  });

  /// The booking being cancelled.
  final ViewState<Booking> view;

  /// The chosen reason.
  final CustomerCancelInputReasonEnum? reason;

  /// Cancelling.
  final bool busy;

  /// Why cancelling failed.
  final AppFailure? failure;

  /// Set once there is no form left to show.
  final CancelOutcome? outcome;
}

CancelOutcome? _outcomeOf(BookingStatus status) => switch (status) {
  BookingStatus.cancelled => CancelOutcome.cancelled,
  BookingStatus.inProgress || BookingStatus.completed => CancelOutcome.blocked,
  BookingStatus.rejected || BookingStatus.timedOut => CancelOutcome.closed,
  _ => null,
};

/// Loads the booking and cancels it with a reason.
class CancelCubit extends Cubit<CancelState> {
  /// Creates the cubit for booking [_id].
  CancelCubit(this._repo, this._id) : super(const CancelState());

  final CancelRepository _repo;
  final String _id;

  /// Loads the booking; one that cannot be cancelled shows why at once.
  Future<void> load() async {
    emit(const CancelState());
    try {
      final b = await _repo.booking(_id);
      emit(CancelState(view: ViewData(b), outcome: _outcomeOf(b.status)));
    } on Object catch (e) {
      emit(CancelState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  /// Chooses [reason].
  void choose(CustomerCancelInputReasonEnum reason) =>
      emit(CancelState(view: state.view, reason: reason));

  /// Cancels with the chosen reason and [note].
  Future<void> submit(String note) async {
    final reason = state.reason;
    if (reason == null) return;
    emit(CancelState(view: state.view, reason: reason, busy: true));
    final text = note.trim();
    try {
      final b = await _repo.cancel(_id, reason, text.isEmpty ? null : text);
      emit(CancelState(view: ViewData(b), outcome: CancelOutcome.cancelled));
    } on Object catch (e) {
      final failure = AppFailure.from(e);
      final blocked = failure.code == 'CANCELLATION_NOT_ALLOWED';
      emit(
        CancelState(
          view: state.view,
          reason: reason,
          failure: blocked ? null : failure,
          outcome: blocked ? CancelOutcome.blocked : null,
        ),
      );
    }
  }
}
