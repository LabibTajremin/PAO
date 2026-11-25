// JSON shapes from api/schemas/delivery.yaml for the scheduled-delivery tests.
import '../booking/booking_fixtures.dart';

/// Service `s1` delivered on a schedule.
Map<String, Object?> scheduledService({
  List<String> patterns = const ['weekdays', 'once', 'weekly', 'monthly'],
}) => {
  ...service(model: 'scheduled_delivery'),
  'schedule': {
    'patterns': patterns,
    'windows': [
      {'start': '12:00', 'end': '13:00'},
      {'start': '13:00', 'end': '14:00'},
    ],
    'leadHours': 12,
    'cutoff': '20:00',
    'unit': 'meals',
    'minQuantity': 1,
    'maxQuantity': 50,
  },
};

/// One date of an order.
Map<String, Object?> deliveryDate(
  String date, {
  String status = 'scheduled',
  bool changeable = true,
  String? bookingId,
}) => {
  'date': date,
  'status': status,
  'items': [
    {'subServiceId': 'x1', 'quantity': 2},
  ],
  'total': 100000,
  'changeable': changeable,
  'bookingId': ?bookingId,
};

/// Order `o1` with [upcoming] dates.
Map<String, Object?> subscription({
  String status = 'active',
  List<Map<String, Object?>>? upcoming,
}) => {
  'id': 'o1',
  'number': 'PAO-S-500001',
  'status': status,
  'serviceId': 's1',
  'serviceName': fanRepair,
  'items': <Object>[],
  'total': 100000,
  'pattern': 'weekdays',
  'weekdays': [0, 1, 2, 3, 4],
  'window': {'start': '12:00', 'end': '13:00'},
  'startDate': '2026-10-11',
  'address': {'area': 'Banani'},
  'createdAt': '2026-10-09T04:00:00Z',
  'upcoming':
      upcoming ??
      [
        deliveryDate(
          '2026-10-11',
          status: 'delivered',
          changeable: false,
          bookingId: 'b1',
        ),
        deliveryDate('2026-10-12'),
        deliveryDate('2026-10-13', status: 'skipped'),
      ],
};
