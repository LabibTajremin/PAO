import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_admin/features/level2/domain/level2_repository.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// A session and, while it is open, the checklist to start from.
class SessionDetail {
  /// Creates the detail.
  const SessionDetail(this.row, [this.template = const []]);

  /// The session with names.
  final Level2Row row;

  /// The service's checklist items.
  final List<LocalizedText> template;
}

/// One session in the drawer and the result being recorded.
class SessionState {
  /// Creates the state.
  const SessionState({
    this.view = const ViewLoading(),
    this.busy = false,
    this.failure,
    this.recorded = false,
  });

  /// The session.
  final ViewState<SessionDetail> view;

  /// The result is being saved.
  final bool busy;

  /// Why saving failed.
  final AppFailure? failure;

  /// A result was saved in this drawer.
  final bool recorded;
}

/// Loads a Level 2 session and records its result (A07).
class SessionCubit extends Cubit<SessionState> {
  /// Creates the cubit for session [_id]; call [load] to start.
  SessionCubit(this._repo, this._id) : super(const SessionState());

  final Level2Repository _repo;
  final String _id;

  /// Loads the session, with the checklist when it is still scheduled.
  Future<void> load() async {
    emit(const SessionState());
    try {
      final row = await _repo.session(_id);
      final open = row.session.status == Level2SessionStatusEnum.scheduled;
      final template = open
          ? await _repo.checklist(row.session.serviceId)
          : const <LocalizedText>[];
      if (!isClosed) {
        emit(SessionState(view: ViewData(SessionDetail(row, template))));
      }
    } on Object catch (e) {
      if (!isClosed) emit(SessionState(view: ViewFailure(AppFailure.from(e))));
    }
  }

  /// Saves [result]; the session closes with it.
  Future<void> record(Level2ResultInput result) async {
    final view = state.view;
    if (view is! ViewData<SessionDetail>) return;
    final row = view.data.row;
    emit(SessionState(view: view, busy: true));
    try {
      final session = await _repo.record(_id, result);
      final next = Level2Row(
        session,
        providerName: row.providerName,
        serviceName: row.serviceName,
      );
      if (!isClosed) {
        emit(SessionState(view: ViewData(SessionDetail(next)), recorded: true));
      }
    } on Object catch (e) {
      if (!isClosed) {
        emit(SessionState(view: view, failure: AppFailure.from(e)));
      }
    }
  }
}
