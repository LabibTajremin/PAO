import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pao_core/src/failure.dart';
import 'package:pao_core/src/session/session.dart';

/// Adds the bearer token and, on a 401, refreshes once for every waiting
/// request (single flight) before retrying. A failed refresh signs out as
/// expired (C63).
class AuthInterceptor extends Interceptor {
  /// Creates the interceptor; [refresher] must not carry this interceptor.
  AuthInterceptor({
    required this.sessions,
    required this.dio,
    required this.refresher,
    this.onRefreshed,
  });

  /// Holds the tokens.
  final SessionManager sessions;

  /// Client that re-sends requests after a refresh.
  final Dio dio;

  /// Bare client that calls `/v1/auth/refresh`.
  final Dio refresher;

  /// Called after each successful refresh, e.g. to reload permissions.
  final void Function()? onRefreshed;

  Future<Session?>? _inFlight;
  static const _retriedKey = 'pao.auth.retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = sessions.session?.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[_retriedKey] == true ||
        !sessions.signedIn) {
      return handler.next(err);
    }
    final session = await (_inFlight ??= _refresh().whenComplete(
      () => _inFlight = null,
    ));
    if (session == null) {
      return handler.next(err.copyWith(error: const SessionExpiredFailure()));
    }
    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await dio.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<Session?> _refresh() async {
    final current = sessions.session;
    try {
      final res = await refresher.post<Map<String, Object?>>(
        '/v1/auth/refresh',
        data: {'refreshToken': ?current?.refreshToken},
      );
      final body = res.data!;
      final next = Session(
        accessToken: body['accessToken']! as String,
        refreshToken: body['refreshToken'] as String?,
      );
      await sessions.signIn(next);
      onRefreshed?.call();
      return next;
    } on DioException {
      await sessions.signOut(expired: true);
      return null;
    }
  }
}
