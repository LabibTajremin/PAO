import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_partner/features/notifications/domain/notifications_repository.dart';

/// [NotificationsRepository] on the PAO API.
class ApiNotificationsRepository implements NotificationsRepository {
  /// Creates the repository.
  ApiNotificationsRepository(Dio api) : _api = ProviderApi(api);

  final ProviderApi _api;

  @override
  Future<NotificationList> inbox() async =>
      (await _api.listProviderNotifications()).data!;

  @override
  Future<void> markRead(String id) =>
      _api.markProviderNotificationRead(notificationId: id);

  @override
  Future<void> markAllRead() => _api.markAllProviderNotificationsRead();

  @override
  Future<void> registerDevice(String token) => _api.registerProviderDeviceToken(
    deviceTokenInput: DeviceTokenInput(
      token: token,
      platform: Platform.android,
    ),
  );
}
