import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/notifications/domain/notifications_repository.dart';

/// [NotificationsRepository] on the PAO API.
class ApiNotificationsRepository implements NotificationsRepository {
  /// Creates the repository.
  ApiNotificationsRepository(Dio api) : _api = CustomerApi(api);

  final CustomerApi _api;

  @override
  Future<Paged<Notification>> inbox({String? cursor}) async {
    final res = await _api.listCustomerNotifications(cursor: cursor);
    return Paged(res.data!.items, res.data!.nextCursor);
  }

  @override
  Future<void> markRead(String id) =>
      _api.markCustomerNotificationRead(notificationId: id);

  @override
  Future<void> markAllRead() => _api.markAllCustomerNotificationsRead();

  @override
  Future<void> registerDevice(String token) => _api.registerCustomerDeviceToken(
    deviceTokenInput: DeviceTokenInput(
      token: token,
      platform: Platform.android,
    ),
  );
}
