import 'package:flutter/material.dart';
import 'package:pao_admin/shared/l10n.dart';
import 'package:pao_core/pao_core.dart';

/// One record on a detail screen and the actions that change it; each action
/// answers with the updated record.
class RecordCubit<T> extends LoadCubit<T> {
  /// Creates the cubit over a loader; call `load` to start.
  RecordCubit(super._load);

  /// Runs [action] and shows the record it returns; resolves with the
  /// failure, if any, so the screen can explain it.
  Future<AppFailure?> act(Future<T> Function() action) async {
    late final T record;
    final failure = await attempt(() async => record = await action());
    if (failure == null && !isClosed) emit(ViewData(record));
    return failure;
  }
}

/// Tells the admin how an action went: [done] on success, otherwise why it
/// failed.
void showOutcome(BuildContext context, AppFailure? failure, String done) {
  // The latest outcome replaces an older one rather than queueing behind it.
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(context.failureText(failure) ?? done)),
    );
}
