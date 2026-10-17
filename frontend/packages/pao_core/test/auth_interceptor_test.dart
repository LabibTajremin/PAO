import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

import 'support/fake_adapter.dart';

void main() {
  late FakeAdapter api;
  late FakeAdapter auth;
  late SessionManager sessions;
  late Dio dio;
  var refreshed = 0;

  setUp(() async {
    api = FakeAdapter();
    auth = FakeAdapter();
    refreshed = 0;
    sessions = SessionManager(MemorySessionStore());
    await sessions.signIn(
      const Session(accessToken: 'old', refreshToken: 'r1'),
    );
    dio = fakeDio(api);
    dio.interceptors.add(
      AuthInterceptor(
        sessions: sessions,
        dio: dio,
        refresher: fakeDio(auth),
        onRefreshed: () => refreshed++,
      ),
    );
  });

  test('concurrent 401s share one refresh, then retry', () async {
    api
      ..reply(401)
      ..reply(401)
      ..reply(200, {'n': 1})
      ..reply(200, {'n': 2});
    auth.reply(200, {'accessToken': 'new', 'refreshToken': 'r2'});
    final results = await Future.wait([
      dio.get<Map<String, Object?>>('/a'),
      dio.get<Map<String, Object?>>('/b'),
    ]);
    expect(results.map((r) => r.statusCode), [200, 200]);
    expect(auth.requests, hasLength(1));
    expect(auth.requests.single.data, {'refreshToken': 'r1'});
    expect(api.requests.last.headers['Authorization'], 'Bearer new');
    expect(sessions.session!.refreshToken, 'r2');
    expect(refreshed, 1);
  });

  test('a failed refresh signs out as expired', () async {
    api.reply(401);
    auth.reply(401);
    final err = await dio
        .get<Object?>('/a')
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect(AppFailure.from(err!), isA<SessionExpiredFailure>());
    expect([sessions.signedIn, sessions.expired], [false, true]);
  });

  test('a retried request that fails again is passed on', () async {
    api
      ..reply(401)
      ..reply(401);
    auth.reply(200, {'accessToken': 'new'});
    await expectLater(dio.get<Object?>('/a'), throwsA(isA<DioException>()));
    expect(auth.requests, hasLength(1));
  });

  test('signed-out and non-401 errors pass through untouched', () async {
    api.reply(500);
    await expectLater(dio.get<Object?>('/a'), throwsA(isA<DioException>()));
    await sessions.signOut();
    api.reply(401);
    await expectLater(dio.get<Object?>('/a'), throwsA(isA<DioException>()));
    expect(api.requests.last.headers['Authorization'], isNull);
    expect(auth.requests, isEmpty);
  });
}
