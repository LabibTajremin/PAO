import 'package:pao_customer/app/routes.dart';

// Templates sent while the provider is on the job; the live screen follows
// them (C14).
const _liveTypes = {
  'booking_accepted',
  'provider_on_the_way',
  'provider_arrived',
  'booking_started',
};

/// The screen a notification opens, from its `type` and `bookingId` (the
/// push data and inbox fields set by the notification module, C60).
String pushRoute(Map<String, Object?> data) {
  final id = data['bookingId'];
  final type = data['type'];
  if (id is! String || id.isEmpty) return Routes.notifications;
  if (_liveTypes.contains(type)) return Routes.booking(id, 'live');
  return switch (type) {
    'extras_proposed' => Routes.booking(id, 'extras'),
    'booking_completed' => Routes.booking(id, 'completed'),
    _ => Routes.booking(id),
  };
}
