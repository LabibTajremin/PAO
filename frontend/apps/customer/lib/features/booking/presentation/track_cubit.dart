import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/booking/domain/booking_repository.dart';

/// Statuses after which a booking no longer changes.
const Set<BookingStatus> finalStatuses = {
  BookingStatus.completed,
  BookingStatus.rejected,
  BookingStatus.timedOut,
  BookingStatus.cancelled,
};

/// A booking followed while it changes (C13, C14).
class TrackState {
  /// Creates the state.
  const TrackState({
    this.view = const ViewLoading(),
    this.left,
    this.stale = false,
  });

  /// The booking as last loaded.
  final ViewState<Booking> view;

  /// Time left for the provider to answer; null unless requested.
  final Duration? left;

  /// The last poll failed (often offline); the view shows the last known
  /// booking.
  final bool stale;

  /// The loaded booking, if any.
  Booking? get booking => switch (view) {
    ViewData(:final data) => data,
    _ => null,
  };

  /// The provider ran out of time to answer.
  bool get expired => left == Duration.zero;
}

/// Loads a booking, counts down a request's deadline and polls for changes.
/// Push taps open screens, but foreground pushes are not exposed by
/// `PushService`, so polling keeps an open screen current.
class TrackCubit extends Cubit<TrackState> {
  /// Creates the cubit; `now` is the app clock, `ticks` fires every second
  /// and the booking is fetched every [pollEvery] ticks.
  TrackCubit(
    this._reader,
    this._id, {
    required this._now,
    this._ticks,
    this.pollEvery = 5,
  }) : super(const TrackState());

  final BookingReader _reader;
  final String _id;
  final DateTime Function() _now;
  final Stream<void>? _ticks;

  /// Ticks between two fetches.
  final int pollEvery;

  StreamSubscription<void>? _sub;
  int _count = 0;
  bool _fetching = false;

  /// Loads the booking, showing loading first, and starts following it.
  Future<void> load() async {
    emit(const TrackState());
    await refresh();
    final status = state.booking?.status;
    if (!isClosed && !finalStatuses.contains(status)) {
      _sub ??= (_ticks ?? Stream<void>.periodic(const Duration(seconds: 1)))
          .listen((_) => _tick());
    }
  }

  /// Fetches the booking again; a failure keeps the last known booking.
  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final b = await _reader.booking(_id);
      if (isClosed) return;
      emit(TrackState(view: ViewData(b), left: _left(b)));
      if (finalStatuses.contains(b.status)) _stop();
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.booking == null
            ? TrackState(view: ViewFailure(AppFailure.from(e)))
            : TrackState(view: state.view, left: state.left, stale: true),
      );
    } finally {
      _fetching = false;
    }
  }

  // The deadline is the server's; the clock measures the time left once, then
  // ticks count it down so a wrong device clock cannot stretch it.
  Duration? _left(Booking b) {
    final deadline = b.acceptDeadline;
    if (b.status != BookingStatus.requested || deadline == null) return null;
    final left = state.left ?? deadline.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    _count++;
    final left = state.left;
    if (left != null && left > Duration.zero) {
      final next = left - const Duration(seconds: 1);
      emit(
        TrackState(
          view: state.view,
          left: next.isNegative ? Duration.zero : next,
          stale: state.stale,
        ),
      );
    }
    if (_count % pollEvery == 0) unawaited(refresh());
  }

  // Not awaited: a periodic stream completes its cancel future outside the
  // cubit's zone, and nothing here depends on it.
  void _stop() {
    unawaited(_sub?.cancel());
    _sub = null;
  }

  @override
  Future<void> close() {
    _stop();
    return super.close();
  }
}
