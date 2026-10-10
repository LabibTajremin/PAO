import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/live/domain/live_repository.dart';

/// The extras approval screen (C15).
class ExtrasState {
  /// Creates the state.
  const ExtrasState({
    this.view = const ViewLoading(),
    this.busy = false,
    this.failure,
    this.done = false,
  });

  /// The booking with its proposal.
  final ViewState<Booking> view;

  /// A decision is being sent.
  final bool busy;

  /// Why the decision failed.
  final AppFailure? failure;

  /// Decided; the page returns to the live booking.
  final bool done;

  /// The proposal waiting for a decision, if any.
  ExtrasProposal? get pending => switch (view) {
    ViewData(:final data)
        when data.pendingExtras?.status == ExtrasProposalStatusEnum.pending =>
      data.pendingExtras,
    _ => null,
  };
}

/// Loads the proposal and sends the customer's decision.
class ExtrasCubit extends Cubit<ExtrasState> {
  /// Creates the cubit for booking [_id].
  ExtrasCubit(this._repo, this._id) : super(const ExtrasState());

  final LiveRepository _repo;
  final String _id;

  /// Loads the booking.
  Future<void> load() async {
    emit(const ExtrasState());
    try {
      final booking = await _repo.booking(_id);
      emit(ExtrasState(view: ViewData(booking)));
    } on Object catch (e) {
      emit(ExtrasState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  /// Approves or declines the pending proposal.
  Future<void> decide({required bool approve}) async {
    final proposal = state.pending;
    if (proposal == null) return;
    emit(ExtrasState(view: state.view, busy: true));
    final failure = await attempt(
      () => _repo.decideExtras(_id, proposalId: proposal.id, approve: approve),
    );
    // Someone else's decision or a withdrawn proposal leaves nothing to do
    // here, so the screen closes as if decided.
    final gone = failure?.code == 'NO_PENDING_EXTRAS';
    emit(
      ExtrasState(
        view: state.view,
        failure: gone ? null : failure,
        done: failure == null || gone,
      ),
    );
  }
}
