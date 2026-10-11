import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pao_e2e/stack.dart';

/// A reply: status and JSON body.
typedef Reply = (int, Object?);

/// An in-memory stack: routes keyed `METHOD /path` answer requests, and every
/// request is recorded.
class FakeStack implements HttpClientAdapter {
  /// Handlers per `METHOD /path`.
  final routes = <String, Reply Function(RequestOptions)>{};

  /// Requests received, in order.
  final requests = <RequestOptions>[];

  /// A client talking to this fake.
  StackClient client() =>
      StackClient('http://stack.test', dio: Dio()..httpClientAdapter = this);

  /// Answers `METHOD /path` with [status] and [body].
  void on(String route, int status, [Object? body]) =>
      routes[route] = (_) => (status, body);

  /// The JSON body of the last request to `METHOD /path`.
  Object? bodyOf(String route) =>
      requests.lastWhere((o) => '${o.method} ${o.uri.path}' == route).data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = '${options.method} ${options.uri.path}';
    final (status, body) = routes[route]?.call(options) ?? (404, null);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
