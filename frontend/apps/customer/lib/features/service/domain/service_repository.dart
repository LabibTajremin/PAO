import 'package:pao_api/pao_api.dart';

/// The service detail (C-04).
abstract interface class ServiceRepository {
  /// The service [id] with its sub-services and prices.
  Future<Service> service(String id);
}
