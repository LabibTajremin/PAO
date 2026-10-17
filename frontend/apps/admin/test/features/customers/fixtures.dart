import '../complaints/fixtures.dart';
import '../providers/fixtures.dart';

/// One row of `GET /v1/admin/customers`.
Map<String, Object?> customerSummary({
  String id = customerId,
  String status = 'active',
  double? rating = 4.5,
  String? phone = '+8801812345678',
}) => {
  'id': id,
  'name': 'Nusrat Jahan',
  'phone': ?phone,
  'status': status,
  'bookings': 14,
  'rating': ?rating,
  'createdAt': '2026-02-10T04:00:00Z',
};

/// `GET /v1/admin/customers/{id}`.
Map<String, Object?> customerDetail({
  String status = 'active',
  bool full = true,
}) => {
  'summary': customerSummary(
    status: status,
    rating: full ? 4.5 : null,
    phone: full ? '+8801812345678' : null,
  ),
  'recentBookings': full ? [bookingSummary()] : <Object?>[],
  'complaints': full ? [complaint()] : <Object?>[],
  'statusHistory': full ? [auditEntry(status: 'active')] : <Object?>[],
};
