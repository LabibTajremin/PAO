import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_api/pao_api.dart' show BookingStatus;
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/connectivity/data/start_code_cache.dart';
import 'package:pao_customer/features/live/domain/live_repository.dart';

/// Statuses in which the provider still needs the start code.
const Set<BookingStatus> codeStatuses = {
  BookingStatus.accepted,
  BookingStatus.onTheWay,
  BookingStatus.arrived,
};

/// The start code, from the API or the device cache.
class StartCodeState {
  /// Creates the state.
  const StartCodeState({this.code, this.failure});

  /// The 4 digits, if known.
  final String? code;

  /// Why the last fetch failed.
  final AppFailure? failure;
}

/// Fetches the start code and keeps a copy for offline display (C36).
class StartCodeCubit extends Cubit<StartCodeState> {
  /// Creates the cubit for booking [_id], starting from the cached code.
  StartCodeCubit(this._repo, this._cache, this._id)
    : super(StartCodeState(code: _cache.read(_id)));

  final LiveRepository _repo;
  final StartCodeCache _cache;
  final String _id;

  /// Fetches the code; a failure keeps the cached one.
  Future<void> load() async {
    try {
      final code = await _repo.startCode(_id);
      await _cache.save(_id, code);
      if (!isClosed) emit(StartCodeState(code: code));
    } on Object catch (e) {
      if (!isClosed) {
        emit(StartCodeState(code: state.code, failure: AppFailure.from(e)));
      }
    }
  }

  /// Forgets the cached code once the booking is past needing it.
  Future<void> sync(BookingStatus status) async {
    if (!codeStatuses.contains(status)) await _cache.forget(_id);
  }
}
