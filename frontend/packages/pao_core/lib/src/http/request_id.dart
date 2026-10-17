import 'dart:math';

import 'package:dio/dio.dart';

/// Tags each request with an `X-Request-ID` so app and server logs line up.
class RequestIdInterceptor extends Interceptor {
  /// Creates the interceptor; [random] is injectable for tests.
  RequestIdInterceptor({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Header name the API reads and echoes.
  static const header = 'X-Request-ID';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(header, _newId);
    handler.next(options);
  }

  String _newId() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
