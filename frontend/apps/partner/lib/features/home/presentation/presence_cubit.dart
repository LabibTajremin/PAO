import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/home/domain/heartbeat.dart';
import 'package:pao_partner/features/home/domain/home_repository.dart';
import 'package:pao_partner/features/home/domain/online_memory.dart';

/// The online toggle (P-04).
class OnlineState {
  /// Creates the state.
  const OnlineState({
    this.online = false,
    this.busy = false,
    this.locationOff = false,
    this.failure,
  });

  /// The provider receives requests and shares their position.
  final bool online;

  /// A switch is in flight.
  final bool busy;

  /// Going online was refused because location is off.
  final bool locationOff;

  /// Why the last switch failed.
  final AppFailure? failure;
}

/// Goes online and offline, and sends the heartbeat while online. The
/// position is read only while online (PRD §11).
class PresenceCubit extends Cubit<OnlineState> {
  /// Creates the cubit.
  PresenceCubit(this._repo, this._location, this._heartbeat, this._memory)
    : super(const OnlineState());

  final HomeRepository _repo;
  final LocationService _location;
  final Heartbeat _heartbeat;
  final OnlineMemory _memory;

  /// Goes back online when the provider was online before.
  Future<void> resume() async {
    if (_memory.online) await goOnline();
  }

  /// Flips the switch.
  Future<void> toggle() => state.online ? goOffline() : goOnline();

  /// Goes online at the current position and starts the heartbeat.
  Future<void> goOnline() async {
    emit(const OnlineState(busy: true));
    final at = await _location.current();
    if (at == null) {
      await _offline(const OnlineState(locationOff: true));
      return;
    }
    try {
      final every = await _repo.goOnline(at);
      await _memory.remember(online: true);
      // A screen closed meanwhile must not leave a heartbeat running.
      if (isClosed) return;
      _heartbeat.start(every, _beat);
      emit(const OnlineState(online: true));
    } on Object catch (e) {
      await _offline(OnlineState(failure: AppFailure.from(e)));
    }
  }

  /// Stops the heartbeat first, so no position is sent once the provider
  /// chose offline, even when the server cannot be told right away.
  Future<void> goOffline() async {
    _heartbeat.stop();
    emit(const OnlineState(online: true, busy: true));
    final failure = await attempt(_repo.goOffline);
    await _offline(OnlineState(failure: failure));
  }

  Future<void> _beat() async {
    final at = await _location.current();
    if (at == null) return;
    final failure = await attempt(() => _repo.heartbeat(at));
    // 409: the server already took the provider offline, e.g. after missed
    // beats or an expired document.
    if (failure is ApiFailure && failure.status == 409) {
      _heartbeat.stop();
      await _offline(OnlineState(failure: failure));
    }
  }

  Future<void> _offline(OnlineState next) async {
    await _memory.remember(online: false);
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() {
    _heartbeat.stop();
    return super.close();
  }
}
