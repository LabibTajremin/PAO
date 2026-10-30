import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// Booking a Level 2 session: in flight, failed or [booked].
class ScheduleState {
  /// Creates the state.
  const ScheduleState({this.busy = false, this.failure, this.booked});

  /// The request is in flight.
  final bool busy;

  /// Why booking failed.
  final AppFailure? failure;

  /// The booked session.
  final Level2Session? booked;
}

/// Books a Level 2 session (A07).
class ScheduleCubit extends Cubit<ScheduleState> {
  /// Creates the cubit.
  ScheduleCubit(this._repo) : super(const ScheduleState());

  final Level2Repository _repo;

  /// Books [booking].
  Future<void> submit(Level2Booking booking) async {
    emit(const ScheduleState(busy: true));
    try {
      final session = await _repo.schedule(booking);
      if (!isClosed) emit(ScheduleState(booked: session));
    } on Object catch (e) {
      if (!isClosed) emit(ScheduleState(failure: AppFailure.from(e)));
    }
  }
}
