import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/job/domain/job_repository.dart';

/// A job and the catalog items that may be added to it.
class ExtrasData {
  /// Creates the data.
  const ExtrasData({required this.booking, required this.options});

  /// The job.
  final Booking booking;

  /// Sub-services of the booked service.
  final List<SubService> options;

  /// Whether a proposal is waiting for the customer.
  bool get waiting =>
      booking.pendingExtras?.status == ExtrasProposalStatusEnum.pending;
}

/// The extra-items picker (M19).
class ExtrasState {
  /// Creates the state.
  const ExtrasState({
    this.view = const ViewLoading(),
    this.quantities = const {},
    this.busy = false,
    this.failure,
  });

  /// The job and its options.
  final ViewState<ExtrasData> view;

  /// Picked quantity per sub-service ID; zero is never stored.
  final Map<String, int> quantities;

  /// A proposal is being sent.
  final bool busy;

  /// Why sending failed.
  final AppFailure? failure;

  /// Price of the picked items, in paisa.
  int get addedTotal => switch (view) {
    ViewData(:final data) => data.options.fold(
      0,
      (sum, s) => sum + s.price * (quantities[s.id] ?? 0),
    ),
    _ => 0,
  };
}

/// Picks extra catalog items and proposes them to the customer (PRD §5:
/// free-text prices are not allowed).
class ExtrasCubit extends Cubit<ExtrasState> {
  /// Creates the cubit for booking [_id]; call [load] to start.
  ExtrasCubit(this._repo, this._id) : super(const ExtrasState());

  final JobRepository _repo;
  final String _id;

  /// Loads the job, then the options of its service.
  Future<void> load() async {
    emit(const ExtrasState());
    try {
      final booking = await _repo.job(_id);
      final options = await _repo.extrasFor(booking.serviceId);
      emit(
        ExtrasState(
          view: ViewData(ExtrasData(booking: booking, options: options)),
        ),
      );
    } on Object catch (e) {
      emit(ExtrasState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  /// Sets the quantity of sub-service [id].
  void pick(String id, int quantity) {
    final next = {...state.quantities, id: quantity}
      ..removeWhere((_, q) => q == 0);
    emit(ExtrasState(view: state.view, quantities: next));
  }

  /// Sends the picked items for the customer's approval.
  Future<void> submit() async {
    final data = (state.view as ViewData<ExtrasData>).data;
    emit(
      ExtrasState(view: state.view, quantities: state.quantities, busy: true),
    );
    try {
      final booking = await _repo.proposeExtras(_id, state.quantities);
      emit(
        ExtrasState(
          view: ViewData(ExtrasData(booking: booking, options: data.options)),
        ),
      );
    } on Object catch (e) {
      emit(
        ExtrasState(
          view: state.view,
          quantities: state.quantities,
          failure: AppFailure.from(e),
        ),
      );
    }
  }
}
