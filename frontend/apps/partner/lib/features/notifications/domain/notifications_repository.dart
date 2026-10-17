import 'package:pao_api/pao_api.dart';

/// The in-app inbox and push registration (P-12).
abstract interface class NotificationsRepository {
  /// Newest notifications first, with the unread count.
  Future<NotificationList> inbox();

  /// Marks one notification read.
  Future<void> markRead(String id);

  /// Marks every notification read.
  Future<void> markAllRead();

  /// Registers this Android device's push [token].
  Future<void> registerDevice(String token);
}
