import 'package:pao_partner/app/routes.dart';

// Templates about a request still waiting for an answer; the request screen
// also explains when it has expired.
const _requestTypes = {'booking_requested', 'request_missed'};

/// The screen a notification opens, from its `type` and `bookingId` (the
/// push data and inbox fields set by the notification module).
String pushRoute(Map<String, Object?> data) {
  final id = data['bookingId'];
  final type = data['type'];
  if (id is String && id.isNotEmpty) {
    return _requestTypes.contains(type)
        ? Routes.requestOf(id)
        : Routes.job(id, 'live');
  }
  if (type is String && type.startsWith('document_')) {
    return Routes.profilePage('documents');
  }
  return type == 'level_changed'
      ? Routes.profilePage('level')
      : Routes.notifications;
}
