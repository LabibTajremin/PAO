import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';

/// The merchant's scheduled-delivery orders on the PAO API (ADR-0041).
class DeliveryRepository {
  /// Creates the repository.
  DeliveryRepository(Dio api) : _api = ProviderSubscriptionsApi(api);

  final ProviderSubscriptionsApi _api;

  /// Orders with [status], newest first.
  Future<List<Subscription>> list(SubscriptionStatus status) async =>
      (await _api.listProviderSubscriptions(status: status)).data!.items;

  /// One order with its next dates.
  Future<Subscription> subscription(String id) async =>
      (await _api.getProviderSubscription(subscriptionId: id)).data!;

  /// Accepts a new order.
  Future<void> accept(String id) => _api.acceptSubscription(subscriptionId: id);

  /// Declines a new order with [reason] and an optional [note].
  Future<void> decline(String id, RejectInputReasonEnum reason, String? note) =>
      _api.declineSubscription(
        subscriptionId: id,
        rejectInput: RejectInput(reason: reason, note: note),
      );

  /// Declines one date (`yyyy-mm-dd`) before its cutoff.
  Future<void> declineDate(String id, String date) =>
      _api.declineDelivery(subscriptionId: id, date: date);

  /// Deliveries between two dates (`yyyy-mm-dd`), by date and window.
  Future<List<ProviderDelivery>> deliveries(String from, String to) async =>
      (await _api.listProviderDeliveries(from: from, to: to)).data!.items;
}
