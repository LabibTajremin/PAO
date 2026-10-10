import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/requests/domain/request_repository.dart';

/// How a request ended for this screen.
enum RequestOutcome {
  /// The provider accepted; the job screen opens.
  accepted,

  /// The provider rejected it.
  rejected,

  /// The deadline passed or it was answered elsewhere.
  expired,
}

// Answers that mean the request is no longer open, so the screen shows the
// expired state instead of an error.
const _gone = {'ACCEPT_DEADLINE_PASSED', 'BOOKING_ALREADY_RESPONDED'};

/// The incoming request screen (M16).
class RequestState {
  /// Creates the state.
  const RequestState({
    this.view = const ViewLoading(),
    this.left,
    this.busy = false,
    this.failure,
    this.outcome,
  });

  /// The request.
  final ViewState<Booking> view;

  /// Time left to answer; null when the request has no deadline.
  final Duration? left;

  /// An answer is being sent.
  final bool busy;

  /// Why the last answer failed.
  final AppFailure? failure;

  /// Set once the request is answered or expired.
  final RequestOutcome? outcome;

  /// A copy with changes; [failure] is replaced, not kept.
  RequestState copyWith({
    Duration? left,
    bool? busy,
    AppFailure? failure,
    RequestOutcome? outcome,
  }) => RequestState(
    view: view,
    left: left ?? this.left,
    busy: busy ?? this.busy,
    failure: failure,
    outcome: outcome ?? this.outcome,
  );
}

/// Loads a request, counts down to the server's deadline and answers it.
class RequestCubit extends Cubit<RequestState> {
  /// Creates the cubit; `now` is the app clock and [ticks] fires every second.
  RequestCubit(this._repo, this._id, {required this._now, Stream<void>? ticks})
    : _ticks = ticks ?? Stream<void>.periodic(const Duration(seconds: 1)),
      super(const RequestState());

  final RequestRepository _repo;
  final String _id;
  final DateTime Function() _now;
  final Stream<void> _ticks;
  StreamSubscription<void>? _sub;

  /// Loads the request and starts the countdown.
  Future<void> load() async {
    emit(const RequestState());
    try {
      _show(await _repo.request(_id));
    } on Object catch (e) {
      emit(RequestState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  // The deadline is the server's; the clock only measures the time left once,
  // then the countdown runs on ticks so a wrong device clock cannot extend it.
  void _show(Booking b) {
    final left = b.acceptDeadline?.difference(_now());
    final open =
        b.status == BookingStatus.requested &&
        (left == null || left > Duration.zero);
    emit(
      RequestState(
        view: ViewData(b),
        left: left,
        outcome: open ? null : RequestOutcome.expired,
      ),
    );
    if (open && left != null) _sub = _ticks.listen((_) => _tick());
  }

  void _tick() {
    final left = state.left! - const Duration(seconds: 1);
    if (left > Duration.zero) {
      return emit(state.copyWith(left: left, failure: state.failure));
    }
    _stop();
    emit(state.copyWith(left: Duration.zero, outcome: RequestOutcome.expired));
  }

  /// Accepts the request.
  Future<void> accept() =>
      _respond(RequestOutcome.accepted, () => _repo.accept(_id));

  /// Rejects the request with [reason].
  Future<void> reject(RejectInputReasonEnum reason, String? note) =>
      _respond(RequestOutcome.rejected, () => _repo.reject(_id, reason, note));

  Future<void> _respond(
    RequestOutcome outcome,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(busy: true));
    final failure = await attempt(action);
    final gone = _gone.contains(failure?.code);
    if (failure == null || gone) _stop();
    emit(
      state.copyWith(
        busy: false,
        failure: gone ? null : failure,
        outcome: failure == null
            ? outcome
            : (gone ? RequestOutcome.expired : null),
      ),
    );
  }

  // Not awaited: a periodic stream completes its cancel future outside the
  // cubit's zone, and nothing here depends on it.
  void _stop() => unawaited(_sub?.cancel());

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}
