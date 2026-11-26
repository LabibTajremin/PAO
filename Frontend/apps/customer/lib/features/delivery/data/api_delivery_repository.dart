import 'package:dio/dio.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/features/delivery/domain/delivery_repository.dart';

/// [DeliveryRepository] on the PAO API.
class ApiDeliveryRepository implements DeliveryRepository {
  /// Creates the repository.
  ApiDeliveryRepository(Dio api) : _api = CustomerSubscriptionsApi(api);

  final CustomerSubscriptionsApi _api;

  @override
  Future<Subscription> create(
    SubscriptionCreate request, {
    required String key,
  }) async => (await _api.createSubscription(
    idempotencyKey: key,
    subscriptionCreate: request,
  )).data!;

  @override
  Future<List<Subscription>> list() async =>
      (await _api.listCustomerSubscriptions()).data!.items;

  @override
  Future<Subscription> subscription(String id) async =>
      (await _api.getCustomerSubscription(subscriptionId: id)).data!;

  @override
  Future<Subscription> move(String id, SubscriptionMove move) async =>
      (await switch (move) {
        SubscriptionMove.pause => _api.pauseSubscription(subscriptionId: id),
        SubscriptionMove.resume => _api.resumeSubscription(subscriptionId: id),
        SubscriptionMove.cancel => _api.cancelSubscription(subscriptionId: id),
      }).data!;

  @override
  Future<DeliveryDate> skip(
    String id,
    String date, {
    required bool skip,
  }) async => (await _api.changeDelivery(
    subscriptionId: id,
    date: date,
    deliveryChange: DeliveryChange(skip: skip),
  )).data!;
}
