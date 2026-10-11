import 'dart:math';

import 'package:dio/dio.dart';

/// Gives one simulated device its own client address. The API allows ten
/// one-time codes per address an hour and trusts `X-Forwarded-For` from a
/// private peer (its load balancer; on the e2e stack, Docker's gateway), so
/// without this every journey on the machine would share one budget.
class ClientAddress extends Interceptor {
  /// Creates the interceptor for [ip], a random `10.x.y.z` when omitted.
  ClientAddress([String? ip]) : ip = ip ?? _random();

  /// The address sent.
  final String ip;

  static String _random() {
    final r = Random();
    return '10.${r.nextInt(256)}.${r.nextInt(256)}.${1 + r.nextInt(254)}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Forwarded-For'] = ip;
    handler.next(options);
  }
}
