import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

/// The in-app inbox and push registration (C-13).
abstract interface class NotificationsRepository {
  /// One page of notifications, newest first.
  Future<Paged<Notification>> inbox({String? cursor});

  /// Marks one notification read.
  Future<void> markRead(String id);

  /// Marks every notification read.
  Future<void> markAllRead();

  /// Registers this Android device's push [token].
  Future<void> registerDevice(String token);
}
