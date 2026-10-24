import 'package:flutter_test/flutter_test.dart';
import 'package:pao_e2e/stack.dart';

import 'support/fake_stack.dart';

const _p = ApiSession(id: 'p1', token: 't');
const _base = '/v1/provider/enrolment';

FakeStack _signInStack() => FakeStack()
  ..on('POST /v1/auth/otp/request', 202)
  ..on('GET /__test/sms', 200, {'message': 'Your PAO code is 654321'})
  ..on('POST /v1/auth/otp/verify', 200, {
    'accessToken': 'acc',
    'account': {'id': 'p1'},
  });

void _uploads(FakeStack fake, {int put = 200}) => fake
  ..on('POST /v1/provider/uploads', 201, {
    'mediaId': 'm1',
    'uploadUrl': 'http://s3.test/put',
    'headers': {'Content-Type': 'image/jpeg'},
  })
  ..on('PUT /put', put, {})
  ..on('POST /v1/provider/uploads/m1/confirm', 200, {});

void main() {
  test('a unique phone with the prefix', () {
    final phone = uniquePhone('017', 3);
    expect(phone, matches(RegExp(r'^017\d{8}$')));
  });

  test('signs in with the texted code', () async {
    final fake = _signInStack();
    final s = await PartnerDriver(fake.client()).signIn('01712345678');
    expect([s.id, s.token], ['p1', 'acc']);
    expect(fake.bodyOf('POST /v1/auth/otp/verify'), {
      'phone': '01712345678',
      'code': '654321',
      'app': 'partner',
    });
  });

  test('enrols every step, confirms the contact and submits', () async {
    final fake = _signInStack()
      ..on('GET /v1/provider/catalog', 200, {
        'categories': [
          {
            'services': [
              {
                'id': 's0',
                'name': {'en': 'Plumber'},
              },
              {
                'id': 's1',
                'name': {'en': 'Electrician'},
              },
            ],
          },
        ],
      })
      ..on('POST $_base/emergency-contact/verify', 200, {})
      ..on('POST $_base/submit', 200, {});
    _uploads(fake);
    for (final step in [
      'personal',
      'services',
      'area',
      'code-of-conduct',
      'emergency-contact',
      'nid',
      'selfie',
      'police-clearance',
    ]) {
      fake.on('PUT $_base/$step', 200, {});
    }
    await PartnerDriver(fake.client()).enrol(
      _p,
      Enrolment(phone: uniquePhone('018'), serviceName: 'Electrician'),
    );
    expect(fake.bodyOf('PUT $_base/services'), {
      'serviceIds': ['s1'],
      'experienceYears': 8,
    });
    expect(
      (fake.bodyOf('PUT $_base/emergency-contact')! as Json)['phone'],
      matches(RegExp(r'^019\d{8}$')),
    );
    expect(fake.requests.last.uri.path, '$_base/submit');
  });

  test('an unknown service and a refused upload fail', () async {
    final fake = FakeStack()
      ..on('GET /v1/provider/catalog', 200, {'categories': <Object?>[]});
    _uploads(fake, put: 403);
    final partner = PartnerDriver(fake.client());
    await expectLater(
      partner.serviceId(_p, 'Nope'),
      throwsA(isA<StackError>()),
    );
    await expectLater(partner.upload(_p, 'selfie'), throwsA(isA<StackError>()));
  });

  test('waits for review and for the right to go online', () async {
    var reads = 0;
    final fake = FakeStack();
    fake.routes['GET /v1/provider/verification'] = (_) => (
      200,
      {
        'items': [
          {'required': false, 'status': 'missing'},
          {'required': true, 'status': ++reads == 1 ? 'missing' : 'pending'},
        ],
      },
    );
    var tries = 0;
    fake.routes['POST /v1/provider/presence/online'] = (_) =>
        ++tries == 1 ? (403, null) : (200, {});
    final partner = PartnerDriver(fake.client());
    await partner.awaitReview(_p);
    await partner.goOnline(_p);
    expect([reads, tries], [2, 2]);
  });

  test('works a job from the request to completion', () async {
    var lists = 0;
    final fake = FakeStack()
      ..on('POST /v1/provider/jobs/b1/accept', 200, {})
      ..on('POST /v1/provider/jobs/b1/start', 200, {})
      ..on('POST /v1/provider/jobs/b1/complete', 200, {});
    fake.routes['GET /v1/provider/jobs'] = (o) {
      expect(o.uri.queryParameters['tab'], 'requests');
      return (
        200,
        {
          'items': ++lists == 1
              ? <Object?>[]
              : [
                  {'id': 'b1'},
                ],
        },
      );
    };
    final job = JobDriver(fake.client(), _p);
    final id = await job.nextRequest();
    await job.mark(id, 'accept');
    await job.start(id, '4821');
    await job.complete(id);
    expect(fake.bodyOf('POST /v1/provider/jobs/b1/start'), {'code': '4821'});
    expect(fake.bodyOf('POST /v1/provider/jobs/b1/complete'), {
      'cashReceived': true,
    });
  });
}
