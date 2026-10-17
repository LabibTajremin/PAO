import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/notifications/domain/notifications_repository.dart';

/// The inbox with read marking.
class NotificationsCubit extends LoadCubit<NotificationList> {
  /// Creates the cubit; call [load] to start.
  NotificationsCubit(NotificationsRepository repo)
    : _repo = repo,
      super(repo.inbox);

  final NotificationsRepository _repo;

  /// Marks [id] read; a failure only leaves it unread, so it is not shown.
  Future<void> markRead(String id) async {
    await attempt(() => _repo.markRead(id));
    await refresh();
  }

  /// Marks everything read.
  Future<void> readAll() async {
    await attempt(_repo.markAllRead);
    await refresh();
  }
}
