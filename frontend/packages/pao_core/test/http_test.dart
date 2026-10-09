import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

import 'support/fake_adapter.dart';

void main() {
  test('every request gets a 32-hex request ID unless it has one', () async {
    final adapter = FakeAdapter()
      ..reply(200)
      ..reply(200);
    final dio = fakeDio(adapter)
      ..interceptors.add(RequestIdInterceptor(random: Random(1)));
    await dio.get<Object?>('/a');
    await dio.get<Object?>(
      '/b',
      options: Options(headers: {RequestIdInterceptor.header: 'mine'}),
    );
    final first = adapter.requests[0].headers[RequestIdInterceptor.header];
    expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(adapter.requests[1].headers[RequestIdInterceptor.header], 'mine');
    expect(RequestIdInterceptor().runtimeType, RequestIdInterceptor);
  });

  group('retry', () {
    Dio client(FakeAdapter adapter) {
      final dio = fakeDio(adapter);
      return dio
        ..interceptors.add(
          RetryInterceptor(dio, delays: [Duration.zero, Duration.zero]),
        );
    }

    test('a GET that never reached the server is retried', () async {
      final adapter = FakeAdapter()
        ..fail(DioExceptionType.connectionError)
        ..fail(DioExceptionType.receiveTimeout)
        ..reply(200, {'ok': true});
      final res = await client(adapter).get<Map<String, Object?>>('/x');
      expect(res.data!['ok'], isTrue);
      expect(adapter.requests, hasLength(3));
    });

    test('the budget runs out', () async {
      final adapter = FakeAdapter();
      for (var i = 0; i < 3; i++) {
        adapter.fail(DioExceptionType.connectionTimeout);
      }
      await expectLater(
        client(adapter).get<Object?>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(3));
    });

    test('writes and server errors are not retried', () async {
      final adapter = FakeAdapter()
        ..fail(DioExceptionType.connectionError)
        ..reply(500);
      final dio = client(adapter);
      await expectLater(dio.post<Object?>('/x'), throwsA(isA<DioException>()));
      await expectLater(dio.get<Object?>('/x'), throwsA(isA<DioException>()));
      expect(adapter.requests, hasLength(2));
    });

    test('default delays wait before retrying', () {
      expect(RetryInterceptor(Dio()).delays, hasLength(2));
    });
  });

  test('createApiClient wires options and interceptors', () async {
    final adapter = FakeAdapter()..reply(200, {'ok': true});
    final sessions = SessionManager(MemorySessionStore());
    await sessions.signIn(const Session(accessToken: 'a'));
    final dio = createApiClient(
      const Env(apiBaseUrl: 'http://api.test', flavour: 'dev'),
      sessions,
      adapter: adapter,
    );
    await dio.get<Object?>('/v1/me');
    final sent = adapter.requests.single;
    expect(sent.uri.toString(), 'http://api.test/v1/me');
    expect(sent.headers['Authorization'], 'Bearer a');
    expect(sent.headers[RequestIdInterceptor.header], isNotNull);
    expect(sent.connectTimeout, const Duration(seconds: 15));
    final plain = createApiClient(
      const Env(apiBaseUrl: 'http://x', flavour: 'dev'),
      sessions,
    );
    expect(plain.httpClientAdapter, isNot(adapter));
  });
}
