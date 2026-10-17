import 'package:dio/dio.dart';

/// Retries GET requests that failed before reaching the server. Other methods
/// are never retried: repeating a write could book twice (PRD §11, slow 3G).
class RetryInterceptor extends Interceptor {
  /// Creates the interceptor that re-sends through [dio] after each [delays]
  /// entry.
  RetryInterceptor(
    this.dio, {
    this.delays = const [Duration(seconds: 1), Duration(seconds: 3)],
  });

  /// Client used to re-send the request.
  final Dio dio;

  /// Waits before each retry; its length is the retry budget.
  final List<Duration> delays;

  static const _attemptKey = 'pao.retry.attempt';

  static bool _transient(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (options.method != 'GET' ||
        !_transient(err) ||
        attempt >= delays.length) {
      return handler.next(err);
    }
    await Future<void>.delayed(delays[attempt]);
    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await dio.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
