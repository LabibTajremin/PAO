import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/src/failure.dart';

/// What a screen shows: loading, the data, or a failure to explain.
sealed class ViewState<T> {
  const ViewState();
}

/// Waiting for the first result.
final class ViewLoading<T> extends ViewState<T> {
  /// Creates the state.
  const ViewLoading();
}

/// The loaded value.
final class ViewData<T> extends ViewState<T> {
  /// Creates the state with [data].
  const ViewData(this.data);

  /// The value.
  final T data;
}

/// Loading failed.
final class ViewFailure<T> extends ViewState<T> {
  /// Creates the state with [failure].
  const ViewFailure(this.failure);

  /// Why it failed.
  final AppFailure failure;
}

/// Loads one value and exposes it as a [ViewState]; feature cubits extend it
/// with their actions.
class LoadCubit<T> extends Cubit<ViewState<T>> {
  /// Creates the cubit; call [load] to start.
  LoadCubit(this._load) : super(const ViewLoading());

  final Future<T> Function() _load;

  /// (Re)loads the value, showing loading first.
  Future<void> load() async {
    emit(const ViewLoading());
    await refresh();
  }

  /// Reloads without the loading state, e.g. after an action.
  Future<void> refresh() async {
    try {
      final value = await _load();
      if (!isClosed) emit(ViewData(value));
    } on Object catch (e) {
      if (!isClosed) emit(ViewFailure(AppFailure.from(e)));
    }
  }
}

/// Runs [action] and returns its failure, if any, so cubits can show it inline.
Future<AppFailure?> attempt(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } on Object catch (e) {
    return AppFailure.from(e);
  }
}
