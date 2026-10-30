import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';

// A self-signed P-256 certificate for api.pao.test and its key's pin, from
// `openssl x509 -pubkey -noout | openssl pkey -pubin -outform der
//  | openssl dgst -sha256 -binary | base64`.
final Uint8List _der = base64.decode(
  'MIIBhDCCASmgAwIBAgIUBIfCGUTz76MmeDiTaipzLlifab4wCgYIKoZIzj0EAwIwFzEVMBMGA1UE'
  'AwwMYXBpLnBhby50ZXN0MB4XDTI2MTAxMjEzNDczM1oXDTM2MTAwOTEzNDczM1owFzEVMBMGA1UE'
  'AwwMYXBpLnBhby50ZXN0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+9pALB0Vtm0zafNPRFcV'
  'RJI1KZRlaEAosfG5LRfe793HfJie422/4l5qnyqEU6B7W0lPZr1cBtOFbxFZhFmOLqNTMFEwHQYD'
  'VR0OBBYEFCSNM11yYdMd2QuqsQvmAazWk2E8MB8GA1UdIwQYMBaAFCSNM11yYdMd2QuqsQvmAazW'
  'k2E8MA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDSQAwRgIhAKfbtkV05BSeJG4TZ86PkRdt'
  'zeOz58UkLgCGmVZOLQHjAiEAhls4+ibikSyrOOevhWaUJ8fmojQ/oqlVkzTOjnmx3Zo=',
);
const _pin = 'GnleuResPFQHJ7pVdgX8Q670+dMABoRCG5jfQu7/S+U=';
const _backup = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

class _FakeCertificate extends Fake implements X509Certificate {
  _FakeCertificate(this.der);

  @override
  final Uint8List der;
}

Env _env(String pins) => Env(
  apiBaseUrl: 'https://api.pao.test',
  flavour: 'prod',
  certificatePins: pins,
);

void main() {
  group('pins', () {
    test('accept a certificate carrying a pinned key', () {
      expect(CertificatePins.parse('$_backup, $_pin').accepts(_der), isTrue);
    });

    test('refuse a certificate with another key', () {
      expect(CertificatePins.parse(_backup).accepts(_der), isFalse);
    });

    test('refuse bytes that are not a certificate', () {
      final pins = CertificatePins.parse(_pin);
      expect(
        pins.accepts(Uint8List.fromList([0x30, 0x82, 0xff, 0xff])),
        isFalse,
      );
      expect(pins.accepts(Uint8List(0)), isFalse);
    });

    test('find no key where the sixth field is not a sequence', () {
      final noVersion = Uint8List.fromList([
        0x30, 0x0e, 0x30, 0x0c, //
        for (var i = 0; i < 6; i++) ...[0x02, 0x00],
      ]);
      expect(subjectPublicKeyInfo(noVersion), isNull);
    });

    test('are empty when the define is blank', () {
      expect(CertificatePins.parse(' , ').isEmpty, isTrue);
      expect(Env.fromDefines().certificatePins, isEmpty);
    });
  });

  group('pinning adapter', () {
    test('is absent outside release builds and without pins', () {
      expect(pinningAdapter(_env(_pin)), isNull);
      expect(pinningAdapter(_env(''), release: true), isNull);
    });

    test('checks the server certificate against the pins in release', () {
      final adapter = pinningAdapter(_env(_pin), release: true)!;
      final check = (adapter as IOHttpClientAdapter).validateCertificate!;
      expect(check(_FakeCertificate(_der), 'api.pao.test', 443), isTrue);
      expect(check(null, 'api.pao.test', 443), isFalse);
      final other = pinningAdapter(_env(_backup), release: true)!;
      final refuse = (other as IOHttpClientAdapter).validateCertificate!;
      expect(refuse(_FakeCertificate(_der), 'api.pao.test', 443), isFalse);
    });
  });
}
