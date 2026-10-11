import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/stack.dart';

import 'support/fake_stack.dart';

const _secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

AdminDriver _driver(
  FakeStack fake,
  SecretStore secrets,
  List<Duration> waits,
) => AdminDriver(
  fake.client(),
  password: 'pw',
  secrets: secrets,
  now: () => DateTime.fromMillisecondsSinceEpoch(61000),
  wait: (d) async => waits.add(d),
);

void main() {
  test(
    'enrols on the first sign-in, keeps the key and reuses the session',
    () async {
      final fake = FakeStack()
        ..on('POST /v1/auth/admin/login', 200, {
          'challengeId': 'c1',
          'totpEnrolment': {'secret': _secret},
        })
        ..on('POST /v1/auth/admin/totp', 200, {'accessToken': 'tok'});
      final secrets = MemorySecrets();
      final admin = _driver(fake, secrets, []);
      final session = await admin.signIn('verifier@pao.bd');
      expect([session.id, session.token], ['verifier@pao.bd', 'tok']);
      expect(await secrets.read('verifier@pao.bd'), _secret);
      expect(fake.bodyOf('POST /v1/auth/admin/totp'), {
        'challengeId': 'c1',
        'code': totp(_secret, DateTime.fromMillisecondsSinceEpoch(61000)),
      });
      await admin.signIn('verifier@pao.bd');
      expect(fake.requests, hasLength(2));
    },
  );

  test('a code used a moment ago is retried in the next window', () async {
    var tries = 0;
    final fake = FakeStack()
      ..on('POST /v1/auth/admin/login', 200, {'challengeId': 'c1'});
    fake.routes['POST /v1/auth/admin/totp'] = (_) =>
        ++tries == 1 ? (401, null) : (200, {'accessToken': 'tok'});
    final waits = <Duration>[];
    final admin = _driver(fake, MemorySecrets({'a@pao.bd': _secret}), waits);
    expect((await admin.signIn('a@pao.bd')).token, 'tok');
    expect(waits, [const Duration(seconds: 29)]);
  });

  test('fails without a key or when the code is refused twice', () async {
    final fake = FakeStack()
      ..on('POST /v1/auth/admin/login', 200, {'challengeId': 'c1'})
      ..on('POST /v1/auth/admin/totp', 401, {'error': 'TOTP_INVALID'});
    await expectLater(
      _driver(fake, MemorySecrets(), []).signIn('a@pao.bd'),
      throwsA(isA<StackError>()),
    );
    await expectLater(
      _driver(
        fake,
        MemorySecrets({'a@pao.bd': _secret}),
        [],
      ).signIn('a@pao.bd'),
      throwsA(isA<StackError>().having((e) => e.message, 'm', contains('401'))),
    );
  });

  test('the verifier approves every item once all are pending', () async {
    var reads = 0;
    final fake = FakeStack()
      ..on('POST /v1/auth/admin/login', 200, {'challengeId': 'c1'})
      ..on('POST /v1/auth/admin/totp', 200, {'accessToken': 'tok'})
      ..on('POST /v1/admin/verifications/p1/items/nid/approve', 200, {})
      ..on('POST /v1/admin/verifications/p1/items/selfie/approve', 200, {});
    fake.routes['GET /v1/admin/verifications/p1'] = (_) => (
      200,
      {
        'items': [
          {'type': 'nid', 'status': 'pending'},
          {'type': 'selfie', 'status': ++reads == 1 ? 'missing' : 'pending'},
          'not an item',
        ],
      },
    );
    final admin = _driver(
      fake,
      MemorySecrets({'verifier@pao.bd': _secret}),
      [],
    );
    await admin.approve('p1', ['nid', 'selfie']);
    expect(
      fake.requests.where((o) => o.uri.path.endsWith('/approve')),
      hasLength(2),
    );
  });
}
