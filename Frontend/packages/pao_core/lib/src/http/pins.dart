import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Base64 SHA-256 hashes of the API's SubjectPublicKeyInfo (MASVS-NETWORK-2).
///
/// Pinning the key rather than the certificate lets certificates be renewed
/// with the same key without an app release; a backup key's hash ships beside
/// the live one so the key itself can be rotated (docs/guides/security-checklist.md).
class CertificatePins {
  /// Pins the given hashes; blanks are ignored.
  CertificatePins(Iterable<String> hashes)
    : _hashes = {
        for (final h in hashes.map((h) => h.trim()))
          if (h.isNotEmpty) h,
      };

  /// Reads the comma-separated `PAO_PIN_SHA256` value.
  factory CertificatePins.parse(String csv) => CertificatePins(csv.split(','));

  final Set<String> _hashes;

  /// No pins: the platform's trust store alone decides.
  bool get isEmpty => _hashes.isEmpty;

  /// Whether the DER certificate carries one of the pinned keys.
  bool accepts(Uint8List certificate) {
    final spki = subjectPublicKeyInfo(certificate);
    if (spki == null) return false;
    return _hashes.contains(base64.encode(sha256.convert(spki).bytes));
  }
}

/// The SubjectPublicKeyInfo of a DER X.509 certificate, or null when the bytes
/// are not one (RFC 5280 §4.1).
Uint8List? subjectPublicKeyInfo(Uint8List der) {
  try {
    final certificate = _Tlv.at(der, 0);
    final tbs = _Tlv.at(der, certificate.body);
    var field = _Tlv.at(der, tbs.body);
    if (field.tag == _explicitVersion) field = _Tlv.at(der, field.end);
    // Serial, signature algorithm, issuer, validity and subject come first.
    for (var i = 0; i < 5; i++) {
      field = _Tlv.at(der, field.end);
    }
    if (field.tag != _sequence) return null;
    return Uint8List.sublistView(der, field.start, field.end);
  } on FormatException {
    return null;
  }
}

const _sequence = 0x30;
const _explicitVersion = 0xa0;

/// One DER tag-length-value header.
class _Tlv {
  _Tlv(this.tag, this.start, this.body, this.end);

  /// Reads the header at [start]; throws [FormatException] when it overruns
  /// [der].
  factory _Tlv.at(Uint8List der, int start) {
    int byte(int i) =>
        i < der.length ? der[i] : throw const FormatException('truncated DER');
    final tag = byte(start);
    var length = byte(start + 1);
    var body = start + 2;
    if (length & 0x80 != 0) {
      final octets = length & 0x7f;
      length = 0;
      for (var i = 0; i < octets; i++) {
        length = (length << 8) | byte(body++);
      }
    }
    if (body + length > der.length) {
      throw const FormatException('truncated DER');
    }
    return _Tlv(tag, start, body, body + length);
  }

  final int tag;
  final int start;
  final int body;
  final int end;
}
