import 'dart:convert';

import 'package:dio/dio.dart';

/// Answers each request with the next queued reply and records what was sent.
class FakeAdapter implements HttpClientAdapter {
  final replies = <Future<ResponseBody> Function(RequestOptions)>[];
  final requests = <RequestOptions>[];

  void reply(int status, [Object? body]) => replies.add(
    (_) async => ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );

  void fail(DioExceptionType type) => replies.add(
    (o) async => throw DioException(requestOptions: o, type: type),
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Reading the body drives Dio's upload progress, as a real socket would.
    await requestStream?.drain<void>();
    return await replies.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;
