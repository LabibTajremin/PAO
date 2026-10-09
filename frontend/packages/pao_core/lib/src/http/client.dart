import 'package:dio/dio.dart';
import 'package:pao_core/src/env.dart';
import 'package:pao_core/src/http/request_id.dart';
import 'package:pao_core/src/http/retry.dart';
import 'package:pao_core/src/session/auth_interceptor.dart';
import 'package:pao_core/src/session/session.dart';

/// Options tuned for slow 3G: generous waits, JSON in and out.
BaseOptions apiOptions(Env env) => BaseOptions(
  baseUrl: env.apiBaseUrl,
  connectTimeout: const Duration(seconds: 15),
  sendTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  contentType: Headers.jsonContentType,
);

/// Builds the API client every app uses. [adapter] lets the admin web app send
/// the refresh cookie (`withCredentials`) and tests mock the network.
Dio createApiClient(
  Env env,
  SessionManager sessions, {
  HttpClientAdapter? adapter,
  void Function()? onRefreshed,
}) {
  Dio build() {
    final dio = Dio(apiOptions(env));
    if (adapter != null) dio.httpClientAdapter = adapter;
    return dio..interceptors.add(RequestIdInterceptor());
  }

  final dio = build();
  dio.interceptors.addAll([
    AuthInterceptor(
      sessions: sessions,
      dio: dio,
      refresher: build(),
      onRefreshed: onRefreshed,
    ),
    RetryInterceptor(dio),
  ]);
  return dio;
}
