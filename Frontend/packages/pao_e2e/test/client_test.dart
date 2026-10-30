import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/stack.dart';

import 'support/fake_stack.dart';

void main() {
  test(
    'sends JSON with a bearer and a client address, and fails loudly',
    () async {
      final fake = FakeStack()
        ..on('GET /v1/me', 200, {'id': 'a1'})
        ..on('POST /v1/list', 201, [1])
        ..on('POST /v1/fail', 409, {'error': 'no'});
      final stack = fake.client();
      final me = await stack.sessionOf('t1');
      expect([me.id, me.token], ['a1', 't1']);
      final sent = fake.requests.single.headers;
      expect(sent['Authorization'], 'Bearer t1');
      expect(sent['X-Forwarded-For'], startsWith('10.'));
      expect(await stack.send('POST', '/v1/list'), isEmpty);
      await expectLater(
        stack.send('POST', '/v1/fail', body: {'a': 1}),
        throwsA(
          isA<StackError>().having((e) => '$e', 'text', contains('got 409')),
        ),
      );
      expect(fake.bodyOf('POST /v1/fail'), {'a': 1});
    },
  );

  test('reads the newest code once the SMS arrives', () async {
    final fake = FakeStack();
    var asked = 0;
    fake.routes['GET /__test/sms'] = (o) {
      expect(o.uri.queryParameters['phone'], '+8801712345678');
      return ++asked < 2 ? (404, null) : (200, {'message': 'PAO code 123456'});
    };
    expect(await fake.client().lastCode('+8801712345678'), '123456');
  });

  test('eventually gives up with what it waited for', () async {
    await expectLater(
      eventually(
        'never',
        () async => false,
        within: const Duration(milliseconds: 30),
        every: const Duration(milliseconds: 10),
      ),
      throwsA(
        isA<StackError>().having((e) => e.message, 'm', contains('never')),
      ),
    );
  });

  test('the stack from the defines and a fixed client address', () {
    expect(StackClient.fromDefines().http.options.baseUrl, '');
    final options = RequestOptions();
    ClientAddress('10.1.2.3').onRequest(options, RequestInterceptorHandler());
    expect(options.headers['X-Forwarded-For'], '10.1.2.3');
  });
}
