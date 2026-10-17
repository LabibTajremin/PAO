import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/notifications/domain/notifications_repository.dart';

/// The paged inbox (C21) with read marking.
class NotificationsCubit extends PagedCubit<Notification> {
  /// Creates the cubit; call [load] to start.
  NotificationsCubit(NotificationsRepository repo)
    : _repo = repo,
      super((cursor) => repo.inbox(cursor: cursor));

  final NotificationsRepository _repo;

  /// Whether any loaded notification is unread.
  bool get hasUnread => state.items.any((n) => !n.read);

  /// Marks [id] read; a failure only leaves it unread, so it is not shown.
  Future<void> markRead(String id) async {
    final failure = await attempt(() => _repo.markRead(id));
    if (failure == null) _mark((n) => n.id == id);
  }

  /// Marks everything read and returns why it failed, if it did.
  Future<AppFailure?> readAll() async {
    final failure = await attempt(_repo.markAllRead);
    if (failure == null) _mark((_) => true);
    return failure;
  }

  // Updates the rows in place: reloading would drop the pages already shown.
  void _mark(bool Function(Notification n) which) {
    if (isClosed) return;
    emit(
      PagedState(
        items: [
          for (final n in state.items)
            if (which(n)) n.copyWith(read: true) else n,
        ],
        next: state.next,
      ),
    );
  }
}
