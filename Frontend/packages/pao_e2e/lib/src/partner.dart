import 'package:dio/dio.dart';
import 'package:pao_e2e/src/client.dart';
import 'package:pao_e2e/src/jpeg.dart';

/// Banani, where every e2e provider works and every e2e customer lives.
const banani = {'lat': 23.7937, 'lng': 90.4066};

/// A Bangladeshi mobile number with [prefix] (e.g. `017`) unique to this run;
/// [n] tells apart numbers made in the same instant.
String uniquePhone(String prefix, [int n = 0]) {
  final tail = (DateTime.now().microsecondsSinceEpoch + n) % 100000000;
  return '$prefix${'$tail'.padLeft(8, '0')}';
}

/// What a provider fills in when enrolling over HTTP.
class Enrolment {
  /// Creates the input.
  const Enrolment({
    required this.phone,
    required this.serviceName,
    this.fullName = 'Rahim Uddin',
  });

  /// The provider's phone.
  final String phone;

  /// English name of the seeded service offered.
  final String serviceName;

  /// Name as on the NID.
  final String fullName;
}

/// The partner app's side of the stack over plain HTTP: sign-in, enrolment,
/// presence.
class PartnerDriver {
  /// Creates the driver.
  const PartnerDriver(this._stack);

  final StackClient _stack;

  /// Signs [phone] in to [app] (`partner` or `customer`) with the texted code.
  Future<ApiSession> signIn(String phone, {String app = 'partner'}) async {
    await _stack.send(
      'POST',
      '/v1/auth/otp/request',
      body: {'phone': phone, 'purpose': 'login'},
    );
    final tokens = await _stack.send(
      'POST',
      '/v1/auth/otp/verify',
      body: {'phone': phone, 'code': await _stack.lastCode(phone), 'app': app},
    );
    final account = tokens['account']! as Json;
    return ApiSession(
      id: '${account['id']}',
      token: '${tokens['accessToken']}',
    );
  }

  /// The ID of the seeded service named [name] in English.
  Future<String> serviceId(ApiSession p, String name) async {
    final tree = await _stack.send('GET', '/v1/provider/catalog', as: p);
    final services = [
      for (final category in tree['categories']! as List<Object?>)
        ...(category! as Json)['services']! as List<Object?>,
    ];
    for (final service in services) {
      if (service case {'id': final String id, 'name': {'en': final String en}}
          when en == name) {
        return id;
      }
    }
    throw StackError('no service $name');
  }

  /// Uploads a small confirmed image through the signed URL, as the app does.
  Future<String> upload(ApiSession p, String purpose) async {
    final body = stubJpeg;
    final ticket = await _stack.send(
      'POST',
      '/v1/provider/uploads',
      body: {
        'purpose': purpose,
        'contentType': 'image/jpeg',
        'sizeBytes': body.length,
      },
      as: p,
    );
    final put = await _stack.http.put<Object?>(
      '${ticket['uploadUrl']}',
      data: Stream.value(body),
      options: Options(
        headers: {...ticket['headers']! as Json, 'Content-Length': body.length},
      ),
    );
    if (put.statusCode != 200) throw StackError('put $purpose: ${put.data}');
    final id = '${ticket['mediaId']}';
    await _stack.send('POST', '/v1/provider/uploads/$id/confirm', as: p);
    return id;
  }

  /// Completes every required enrolment step with documents, confirms the
  /// emergency contact and submits.
  Future<void> enrol(ApiSession p, Enrolment e) async {
    final contact = '019${e.phone.substring(e.phone.length - 8)}';
    final steps = {
      ..._profile(e, await serviceId(p, e.serviceName), contact),
      ...await _documents(p, e),
    };
    const base = '/v1/provider/enrolment';
    for (final MapEntry(:key, :value) in steps.entries) {
      await _stack.send('PUT', '$base/$key', body: value, as: p);
    }
    await _stack.send(
      'POST',
      '$base/emergency-contact/verify',
      body: {'code': await _stack.lastCode(contact)},
      as: p,
    );
    await _stack.send('POST', '$base/submit', as: p);
  }

  /// Waits until the worker has relayed [p]'s submission and every required
  /// item waits for a verifier, so it shows in the review queue.
  Future<void> awaitReview(ApiSession p) =>
      eventually('submission in review', () async {
        final status = await _stack.send(
          'GET',
          '/v1/provider/verification',
          as: p,
        );
        return (status['items']! as List<Object?>).every(
          (item) => switch (item) {
            {'required': true, 'status': final s} => s == 'pending',
            _ => true,
          },
        );
      });

  /// Brings [p] online in Banani once the approved level has reached the
  /// provider module (the worker relays it).
  Future<void> goOnline(ApiSession p) =>
      eventually('provider allowed online', () async {
        final res = await _stack.call(
          'POST',
          '/v1/provider/presence/online',
          body: {'location': banani},
          as: p,
        );
        return res.statusCode == 200;
      });

  /// The steps without documents.
  Map<String, Json> _profile(Enrolment e, String serviceId, String contact) => {
    'personal': {
      'fullName': e.fullName,
      'dateOfBirth': '1990-04-12',
      'gender': 'male',
      'presentAddress': 'House 12, Banani',
      'permanentAddress': 'Cumilla Sadar',
    },
    'services': {
      'serviceIds': [serviceId],
      'experienceYears': 8,
    },
    'area': {'homeBase': banani, 'workingRadiusM': 8000},
    'code-of-conduct': {'version': '2026-10', 'accepted': true},
    'emergency-contact': {
      'name': 'Karim Uddin',
      'relation': 'Brother',
      'phone': contact,
    },
  };

  /// The steps with uploaded documents; the clearance was issued a month ago.
  Future<Map<String, Json>> _documents(ApiSession p, Enrolment e) async {
    final issued = DateTime.now().subtract(const Duration(days: 30));
    return {
      'nid': {
        'nidNumber': '1${e.phone.substring(e.phone.length - 9)}',
        'frontMediaId': await upload(p, 'nid_front'),
        'backMediaId': await upload(p, 'nid_back'),
      },
      'selfie': {'mediaId': await upload(p, 'selfie')},
      'police-clearance': {
        'mediaId': await upload(p, 'police_clearance'),
        'issueDate': issued.toIso8601String().substring(0, 10),
      },
    };
  }
}
