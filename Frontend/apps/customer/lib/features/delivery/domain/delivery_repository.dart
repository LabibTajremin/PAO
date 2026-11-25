import 'package:pao_api/pao_api.dart';

/// The moves a customer makes on a subscription (ADR-0041 §5).
enum SubscriptionMove {
  /// Stops the dates not yet booked.
  pause,

  /// Starts them again.
  resume,

  /// Ends the subscription.
  cancel,
}

/// Scheduled-delivery orders: ordering, reading and changing them (P25).
abstract interface class DeliveryRepository {
  /// Orders [request]; repeating it with the same [key] returns the first
  /// order.
  Future<Subscription> create(
    SubscriptionCreate request, {
    required String key,
  });

  /// My orders, newest first.
  Future<List<Subscription>> list();

  /// One order with its next dates.
  Future<Subscription> subscription(String id);

  /// Pauses, resumes or cancels an order.
  Future<Subscription> move(String id, SubscriptionMove move);

  /// Skips or brings back one date (`yyyy-mm-dd`) before its cutoff.
  Future<DeliveryDate> skip(String id, String date, {required bool skip});
}
